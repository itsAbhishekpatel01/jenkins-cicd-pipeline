FROM node:7.8.0
WORKDIR /opt
COPY . /opt
RUN npm install
EXPOSE 3000
ENTRYPOINT ["npm", "run", "start"]
