# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory in container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 8080 for the backend
EXPOSE 8080

# Set environment variables
ENV NODE_ENV=production
ENV MONGODB_URI=mongodb://mongodb:27017/dd_db

# Start the Node.js server
CMD ["node", "server.js"]
