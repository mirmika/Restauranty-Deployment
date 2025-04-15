FROM node:20

WORKDIR /app

COPY package*.json ./

COPY metrics.cjs ./ 

ENV NODE_ENV=production

RUN npm install 

COPY . .

EXPOSE 3002

CMD ["npm", "start"]
