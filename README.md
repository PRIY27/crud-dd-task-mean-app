In this DevOps task, you need to build and deploy a full-stack CRUD application using the MEAN stack (MongoDB, Express, Angular 15, and Node.js). The backend will be developed with Node.js and Express to provide REST APIs, connecting to a MongoDB database. The frontend will be an Angular application utilizing HTTPClient for communication.  

The application will manage a collection of tutorials, where each tutorial includes an ID, title, description, and published status. Users will be able to create, retrieve, update, and delete tutorials. Additionally, a search box will allow users to find tutorials by title.

## Project setup

### Option 1: Local Development (without Docker)

#### Node.js Server

```bash
cd backend
npm install
node server.js
```

You can update the MongoDB credentials by modifying the `db.config.js` file located in `app/config/`.

#### Angular Client

```bash
cd frontend
npm install
ng serve --port 8081
```

You can modify the `src/app/services/tutorial.service.ts` file to adjust how the frontend interacts with the backend.

Navigate to `http://localhost:8081/`

### Option 2: Docker Deployment

#### Prerequisites
- Docker installed on your machine ([Download Docker](https://www.docker.com/products/docker-desktop))
- Docker Compose

#### Build and Run with Docker Compose

From the project root directory, run:

```bash
docker-compose up --build
```

This will:
- Build the backend Docker image
- Build the frontend Docker image
- Start MongoDB database service
- Start Node.js backend server
- Start Angular frontend server

#### Services and Ports

| Service | Port | URL |
|---------|------|-----|
| Frontend (Angular) | 8081 | http://localhost:8081 |
| Backend (Node.js/Express) | 8080 | http://localhost:8080 |
| MongoDB | 27017 | mongodb://localhost:27017 |

#### Stop the Containers

```bash
docker-compose down
```

#### View Logs

```bash
docker-compose logs -f
```

#### Remove Volumes (clean database)

```bash
docker-compose down -v
```

#### Build Images Separately

Backend:
```bash
docker build -t mean-backend:latest ./backend
```

Frontend:
```bash
docker build -t mean-frontend:latest ./frontend
```

#### Run Containers Individually

```bash
# Start MongoDB
docker run -d -p 27017:27017 --name mean-mongodb mongo:6.0-alpine

# Start Backend
docker run -d -p 8080:8080 --name mean-backend --link mean-mongodb:mongodb mean-backend:latest

# Start Frontend
docker run -d -p 8081:8081 --name mean-frontend mean-frontend:latest
```

#### Environment Variables

The application uses the following environment variables:

- `MONGODB_URI`: MongoDB connection string (default: `mongodb://127.0.0.1:27017/dd_db`)
- `NODE_ENV`: Node environment (default: `production`)

In Docker Compose, these are automatically set to use the MongoDB container.

#### Troubleshooting

1. **Port already in use**: Change the port mapping in `docker-compose.yml`
2. **Container won't start**: Check logs with `docker-compose logs <service-name>`
3. **MongoDB connection fails**: Ensure MongoDB container is healthy before backend starts
4. **Frontend can't reach backend**: Make sure both containers are on the same network (handled by docker-compose)
