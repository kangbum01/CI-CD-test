FROM busybox:stable
WORKDIR /app
RUN echo "Hello CI on K8s!" > /app/index.html
EXPOSE 8080
CMD ["sh","-c","httpd -f -p 8080 -h /app || sleep 3600"]

