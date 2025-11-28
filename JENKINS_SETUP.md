# Jenkins CI/CD Setup Guide

## Overview

This guide walks you through setting up Jenkins to automatically build Docker images, push them to Docker Hub, and deploy your MEAN stack application to a VM.

**Pipeline Flow:**
1. Developer pushes code to GitHub (main branch)
2. Jenkins detects the push (via webhook or polling)
3. Jenkins checks out code and builds backend/frontend Docker images
4. Images are tagged with build number and "latest"
5. Images are pushed to Docker Hub (`priyadarshankhavtode/...`)
6. Jenkins SSHes into the VM and executes deployment
7. VM pulls latest images and restarts docker-compose services

---

## Prerequisites

- Jenkins server (v2.361+) installed and accessible
- Docker installed on Jenkins server (for building images)
- GitHub repository: `PRIY27/crud-dd-task-mean-app`
- Docker Hub account: `priyadarshankhavtode`
- Linux VM with Docker, Docker Compose v2+, and SSH access
- SSH key pair for Jenkins → VM authentication

---

## Step 1: Set Up Jenkins Credentials

### 1.1 Docker Hub Credentials

1. Go to **Jenkins Dashboard** → **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
2. Click **+ Add Credentials**
3. Configure:
   - **Kind:** Username with password
   - **Scope:** Global
   - **Username:** `priyadarshankhavtode`
   - **Password:** Your Docker Hub password or personal access token (recommended)
   - **ID:** `dockerhub-creds` (must match Jenkinsfile)
   - **Description:** Docker Hub credentials for pushing images
4. Click **Create**

### 1.2 SSH Credentials for VM Deployment

1. Generate SSH key on your machine (if you don't have one):
   ```bash
   # Linux/macOS
   ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins_deploy -N ""
   
   # Windows PowerShell
   ssh-keygen -t rsa -b 4096 -f $env:USERPROFILE\.ssh\jenkins_deploy -N ""
   ```

2. Add the public key to the VM:
   ```bash
   # From your local machine
   ssh-copy-id -i ~/.ssh/jenkins_deploy.pub ubuntu@your-vm-ip
   
   # Or manually on the VM:
   mkdir -p ~/.ssh
   echo "PASTE_YOUR_PUBLIC_KEY_HERE" >> ~/.ssh/authorized_keys
   chmod 700 ~/.ssh
   chmod 600 ~/.ssh/authorized_keys
   ```

3. In Jenkins, go to **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
4. Click **+ Add Credentials**
5. Configure:
   - **Kind:** SSH Username with private key
   - **Scope:** Global
   - **Username:** `ubuntu` (or your SSH user on the VM)
   - **Private Key:** Paste the full contents of `~/.ssh/jenkins_deploy` (the private key file)
   - **Passphrase:** (leave empty if no passphrase)
   - **ID:** `deploy-ssh-key` (must match Jenkinsfile)
   - **Description:** SSH key for VM deployment
6. Click **Create**

---

## Step 2: Create Jenkins Pipeline Job

### 2.1 Create a New Pipeline Job

1. **Jenkins Dashboard** → **+ New Item**
2. Enter **Item name:** `crud-dd-task-mean-app` (or any name)
3. Select **Pipeline** and click **OK**

### 2.2 Configure the Pipeline

1. **General** tab:
   - Check **GitHub project**
   - **Project url:** `https://github.com/PRIY27/crud-dd-task-mean-app`
   - (Optional) Check **Build Triggers** → **GitHub hook trigger for GITScm polling**

2. **Build Triggers** tab (choose one):
   - **Poll SCM:** Set `H/5 * * * *` to poll GitHub every 5 minutes
   - OR **GitHub hook trigger:** Set up webhook (see Step 2.3)

3. **Pipeline** tab:
   - **Definition:** Pipeline script from SCM
   - **SCM:** Git
   - **Repository URL:** `https://github.com/PRIY27/crud-dd-task-mean-app.git`
   - **Credentials:** (leave empty for public repo, or add GitHub credentials if private)
   - **Branch Specifier:** `*/main`
   - **Script Path:** `Jenkinsfile`
   - Click **Save**

### 2.3 (Optional) Set Up GitHub Webhook

1. Go to **GitHub** repository → **Settings** → **Webhooks** → **Add webhook**
2. **Payload URL:** `http://your-jenkins-url/github-webhook/`
3. **Content type:** `application/json`
4. **Events:** Select `Push events`
5. Click **Add webhook**

---

## Step 3: Configure Job Parameters

When you run the job, you can override deployment parameters:

1. From the job page, click **Build with Parameters** (or **Build Now** to use defaults)
2. Available parameters:
   - **DEPLOY_HOST:** VM hostname/IP (default: `your.vm.ip.or.hostname`)
   - **DEPLOY_USER:** SSH user on VM (default: `ubuntu`)
   - **COMPOSE_PATH:** Path to docker-compose.yml on VM (default: `/home/ubuntu/crud-dd-task-mean-app`)
   - **SSH_PORT:** SSH port on VM (default: `22`)

---

## Step 4: Prepare Your VM

Ensure your VM has:

1. **Docker installed**
   ```bash
   curl -fsSL https://get.docker.com -o get-docker.sh
   sudo sh get-docker.sh
   sudo usermod -aG docker ubuntu
   newgrp docker  # Apply group changes immediately
   ```

2. **Docker Compose v2+**
   ```bash
   docker compose version
   # Should show: Docker Compose version v2.x.x
   ```

3. **Repository cloned** at the COMPOSE_PATH
   ```bash
   cd /home/ubuntu
   git clone https://github.com/PRIY27/crud-dd-task-mean-app.git
   cd crud-dd-task-mean-app
   ```

4. **SSH key authorized** (done in Step 1.2)

---

## Step 5: Test the Pipeline

### 5.1 Trigger Manually

1. Go to your Jenkins job
2. Click **Build with Parameters**
3. Enter:
   - **DEPLOY_HOST:** Your VM IP or hostname
   - **DEPLOY_USER:** SSH user (usually `ubuntu`)
   - **COMPOSE_PATH:** `/home/ubuntu/crud-dd-task-mean-app`
4. Click **Build**

### 5.2 Monitor Build Progress

1. In the **Build History** (left side), click the build number (e.g., `#1`)
2. Click **Console Output** to see real-time logs
3. Verify each stage:
   - ✅ Checkout
   - ✅ Build Backend Image
   - ✅ Build Frontend Image
   - ✅ Push to Docker Hub
   - ✅ Deploy to VM

### 5.3 Verify on VM

After a successful build, SSH into the VM and check:

```bash
ssh ubuntu@your-vm-ip

# Check running containers
docker compose ps

# Check logs for any issues
docker compose logs --tail=50 backend
docker compose logs --tail=50 frontend
docker compose logs --tail=50 mongodb

# Access the application
curl http://localhost:8080/api/tutorials  # Backend API
curl http://localhost:8081/               # Frontend (if running)
```

---

## Step 6: Set Up Automated Deployment on Push

### Option A: GitHub Webhook (Recommended)

1. Configure webhook in GitHub (see Step 2.3)
2. Every push to `main` will automatically trigger Jenkins

### Option B: Poll SCM

1. In Jenkins job → **Configure** → **Build Triggers**
2. Check **Poll SCM**
3. Set schedule to `H/5 * * * *` (every 5 minutes)
4. Jenkins will check GitHub and trigger builds on code changes

---

## Troubleshooting

### Build fails at "Build Backend Image"

**Problem:** Docker build fails or Docker not found

**Solution:**
- Verify Docker is installed: `docker --version`
- Check Jenkins has permission: `docker ps` should work without sudo
- If using Jenkins in Docker: ensure Docker socket is mounted or Docker is installed in Jenkins container

### Push to Docker Hub fails (401 Unauthorized)

**Problem:** Authentication error

**Solution:**
- Verify credentials in Jenkins:
  - **Manage Jenkins** → **Credentials** → **System** → **Global credentials**
  - Check `dockerhub-creds` has correct username/password
  - Consider using Docker Hub Personal Access Token instead of password
- Test locally:
  ```bash
  docker login -u priyadarshankhavtode
  # Enter password when prompted
  docker logout
  ```

### Deploy to VM fails (SSH error)

**Problem:** SSH connection fails or permission denied

**Solution:**
- Verify SSH key:
  - Check `deploy-ssh-key` credential in Jenkins
  - Verify public key is in VM's `~/.ssh/authorized_keys`
- Test SSH manually from Jenkins server:
  ```bash
  ssh -i /path/to/private/key -p 22 ubuntu@your-vm-ip "docker ps"
  ```
- Check VM firewall allows SSH (port 22 by default)

### Docker Compose fails on VM (image not found)

**Problem:** `docker compose` can't pull the images

**Solution:**
- Verify images were pushed to Docker Hub:
  ```bash
  docker search priyadarshankhavtode/crud-dd-task-mean-app
  ```
- Verify docker-compose.yml references correct image names (should be `priyadarshankhavtode/crud-dd-task-mean-app-backend:latest`, etc.)
- On VM, manually test pull:
  ```bash
  docker pull priyadarshankhavtode/crud-dd-task-mean-app-backend:latest
  ```

---

## Jenkins File Structure

Key files in the repository:

- **`Jenkinsfile`** — Declarative pipeline definition (triggers build, push, deploy)
- **`deploy-remote.sh`** — Deployment script executed on the VM (pulls images, restarts compose)
- **`docker-compose.yml`** — Service configuration (backend, frontend, MongoDB)
- **`backend/Dockerfile`** — Backend image definition
- **`frontend/Dockerfile`** — Frontend image definition

---

## Accessing Your Application

After a successful deployment, access your app:

- **Backend API:** `http://your-vm-ip:8080`
- **Frontend:** `http://your-vm-ip:8081`
- **MongoDB:** `your-vm-ip:27017` (internal, auth required)

Example API calls:

```bash
# Get all tutorials
curl http://your-vm-ip:8080/api/tutorials

# Create a tutorial
curl -X POST http://your-vm-ip:8080/api/tutorials \
  -H "Content-Type: application/json" \
  -d '{"title":"My Tutorial","description":"Test"}'
```

---

## Additional Resources

- [Jenkins Declarative Pipeline Documentation](https://www.jenkins.io/doc/book/pipeline/syntax/)
- [Jenkins Credentials Plugin](https://plugins.jenkins.io/credentials/)
- [Docker Hub API](https://docs.docker.com/docker-hub/api/)

---

**Questions?** Check Jenkins console logs or run:

```bash
# On Jenkins server
docker logs jenkins  # if running in Docker

# On VM
docker compose logs -f  # Follow logs for troubleshooting
```
