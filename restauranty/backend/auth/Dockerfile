FROM node:20

WORKDIR /app

COPY package*.json ./

ENV NODE_ENV=production

RUN npm install 

COPY . .

EXPOSE 3001

CMD ["npm", "start"]
