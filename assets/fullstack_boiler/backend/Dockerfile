FROM node:alpine
WORKDIR /sti
RUN npm install pm2 typescript yarn -g
COPY . /sti
RUN apk --no-cache add --virtual builds-deps build-base python
RUN yarn && yarn build
EXPOSE 8000 5432
CMD ["pm2-runtime", "start", "ecosystem.yml"]
