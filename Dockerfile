FROM busybox:stable
WORKDIR /app
RUN echo "Hello CI on K8s!" > /app/index.html
<<<<<<< HEAD
EXPOSE 8080
=======
>>>>>>> ec62c97 (first commit)
CMD ["sh","-c","httpd -f -p 8080 -h /app || sleep 3600"]
