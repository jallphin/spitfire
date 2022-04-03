FROM node
MAINTAINER [James Allphin](https://twitter.com/c4th3dral_)
cmd ["npm", "start"]

RUN git clone https://github.com/seejohnrun/haste-server.git /opt/haste
WORKDIR /opt/haste
RUN npm install

expose 7777
ADD add /opt/haste/
