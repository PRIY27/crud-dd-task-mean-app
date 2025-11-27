# Use official Node.js runtime as base image
FROM node:18-alpine

# Set working directory in container
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies including Angular CLI
RUN npm install

# Copy the rest of the application code
COPY . .

# Expose port 8081 for the frontend
EXPOSE 8081

# Set environment variable
ENV NODE_ENV=production

# Start the Angular development server
CMD ["npm", "start", "--", "--host", "0.0.0.0", "--port", "8081"]
