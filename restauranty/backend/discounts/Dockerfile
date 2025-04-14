FROM node:14

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production

RUN npm install 

COPY . .

EXPOSE 3002

CMD ["npm", "start"]
