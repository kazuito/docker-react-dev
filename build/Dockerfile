FROM node:10-alpine
LABEL maintainer "Kazuito <kazit.kazuito@gmail.com>"

RUN npm i -g create-react-app
EXPOSE 3000

WORKDIR /opt/app

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["sh", "/entrypoint.sh"]
