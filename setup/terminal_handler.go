package internal

import (
	"encoding/json"
	"io"
	"net/http"
	"os"
	"os/exec"
	"syscall"
	"unsafe"

	"github.com/creack/pty"
	"github.com/gorilla/websocket"
	log "github.com/sirupsen/logrus"
)

const (
	bufferSizeBytes = 1024
)

type windowSize struct {
	Rows uint16 `json:"rows"`
	Cols uint16 `json:"cols"`
	X    uint16
	Y    uint16
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  bufferSizeBytes,
	WriteBufferSize: bufferSizeBytes,
}

func tryWriteMessage(conn *websocket.Conn, messageType int, data []byte) {
	if err := conn.WriteMessage(messageType, data); err != nil {
		log.WithError(err).Error("Unable to write message")
	}
}

func tryWriteTextMessage(conn *websocket.Conn, str string) {
	tryWriteMessage(conn, websocket.TextMessage, []byte(str))
}

func tryWriteBinaryMessage(conn *websocket.Conn, data []byte) {
	tryWriteMessage(conn, websocket.BinaryMessage, data)
}

func handleWebsocket(w http.ResponseWriter, r *http.Request) {
	l := log.WithField("remoteaddr", r.RemoteAddr)
	params := r.URL.Query()

	if key1 := params.Get("key1"); key1 == "foo" {
		return
	}
	upgrader.CheckOrigin = func(r *http.Request) bool { return true }
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		l.WithError(err).Error("Unable to upgrade connection")
		return
	}

	cmd := exec.Command("/bin/bash", "--noprofile", "--norc")
	cmd.Env = append(os.Environ(), "PS1=# ")
	cmd.Env = append(cmd.Env, "TERM=xterm")

	ttyFile, err := pty.Start(cmd)
	if err != nil {
		l.WithError(err).Error("Unable to start pty/cmd")
		tryWriteTextMessage(conn, err.Error())
		return
	}
	defer func() {
		var err error
		if err = cmd.Process.Kill(); err != nil {
			l.WithError(err).Error("Couldn't kill process")
		}
		if _, err = cmd.Process.Wait(); err != nil {
			l.WithError(err).Error("Couldn't wait for process")
		}
		if err = ttyFile.Close(); err != nil {
			l.WithError(err).Error("Couldn't close tty")
		}
		if err = conn.Close(); err != nil {
			l.WithError(err).Error("Couldn't close connection")
		}
	}()

	go sendTtyBuffer(ttyFile, conn)

	for {
		receiveWsBuffer(l, conn, ttyFile)
	}
}

func sendTtyBuffer(ttyFile *os.File, conn *websocket.Conn) {
	for {
		buf := make([]byte, bufferSizeBytes)
		read, err := ttyFile.Read(buf)
		if err != nil {
			tryWriteTextMessage(conn, err.Error())
			return
		}
		tryWriteBinaryMessage(conn, buf[:read])
	}
}

func receiveWsBuffer(l *log.Entry, conn *websocket.Conn, ttyFile *os.File) {
	messageType, reader, err := conn.NextReader()
	if err != nil {
		l.WithError(err).Error("Unable to grab next reader")
		return
	}

	if messageType == websocket.TextMessage {
		l.Warn("Unexpected text message")
		tryWriteTextMessage(conn, "Unexpected text message")
		return
	}

	dataTypeBuf := make([]byte, 1)
	read, err := reader.Read(dataTypeBuf)
	if err != nil {
		l.WithError(err).Error("Unable to read message type from reader")
		tryWriteTextMessage(conn, "Unable to read message type from reader")
		return
	}

	if read != 1 {
		l.WithField("bytes", read).Error("Unexpected number of bytes read")
		return
	}

	switch dataTypeBuf[0] {
	case 0:
		bytesWritten, err := io.Copy(ttyFile, reader)
		if err != nil {
			l.WithError(err).Errorf("Error after copying %d bytes", bytesWritten)
		}
	case 1:
		winSize, err := tryDecodeWindowSize(reader)
		if err != nil {
			tryWriteTextMessage(conn, "Error decoding resize message: "+err.Error())
			return
		}
		resizeTerminal(l, winSize, ttyFile)
	default:
		l.WithField("dataType", dataTypeBuf[0]).Error("Unknown data type")
	}
}

func tryDecodeWindowSize(reader io.Reader) (windowSize, error) {
	winSize := windowSize{}
	decoder := json.NewDecoder(reader)
	err := decoder.Decode(&winSize)
	return winSize, err
}

// #nosec G103
// getString converts byte slice to a string without memory allocation.
// See https://groups.google.com/forum/#!msg/Golang-Nuts/ENgbUzYvCuU/90yGx7GUAgAJ
func resizeTerminal(l *log.Entry, winSize windowSize, ttyFile *os.File) {
	log.WithField("resizeMessage", winSize).Info("Resizing terminal")
	_, _, errno := syscall.Syscall(
		syscall.SYS_IOCTL,
		ttyFile.Fd(),
		syscall.TIOCSWINSZ,
		uintptr(unsafe.Pointer(&winSize)),
	)
	if errno != 0 {
		l.WithError(errno).Error("Unable to resize terminal")
	}
}
