# Dockerfile
# Use official nginx image
FROM nginx:alpine

# Copy build files into nginx html folder
COPY build/ /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
