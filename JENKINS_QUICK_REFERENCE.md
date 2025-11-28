# Jenkins CI/CD - Quick Reference

## Pipeline Overview

**Trigger:** Push to GitHub `main` branch  
**Build:** Backend + Frontend Docker images  
**Push:** Images to Docker Hub (`priyadarshankhavtode/...`)  
**Deploy:** SSH to VM, pull images, restart `docker compose`

## Jenkins Credentials Required

| ID | Type | Value |
|----|------|-------|
| `dockerhub-creds` | Username + Password | Docker Hub username: `priyadarshankhavtode`, password: your token/password |
| `deploy-ssh-key` | SSH Private Key | SSH private key for accessing the VM |

**Location:** Manage Jenkins → Credentials → System → Global credentials

## VM Setup Checklist

- [ ] Docker installed and running
- [ ] Docker Compose v2+ installed
- [ ] Repository cloned at `/home/ubuntu/crud-dd-task-mean-app` (or your COMPOSE_PATH)
- [ ] Jenkins SSH public key added to `~/.ssh/authorized_keys`
- [ ] SSH port 22 (or custom port) is open in firewall

## Files in This Repository

| File | Purpose |
|------|---------|
| `Jenkinsfile` | Pipeline definition (build → push → deploy) |
| `deploy-remote.sh` | Deployment script executed on VM |
| `docker-compose.yml` | Service definitions (backend, frontend, MongoDB) |
| `backend/Dockerfile` | Backend image build instructions |
| `frontend/Dockerfile` | Frontend image build instructions |
| `JENKINS_SETUP.md` | Full setup guide (this document) |

## Build Parameters (when running manually)

```
DEPLOY_HOST      = your.vm.ip.or.hostname
DEPLOY_USER      = ubuntu
COMPOSE_PATH     = /home/ubuntu/crud-dd-task-mean-app
SSH_PORT         = 22
```

## Accessing Your App (after deployment)

- **Backend API:** `http://your-vm-ip:8080/api/tutorials`
- **Frontend:** `http://your-vm-ip:8081`

## Quick Test

From Jenkins Dashboard:

```
1. Click job name → "Build with Parameters"
2. Enter DEPLOY_HOST (your VM IP)
3. Click "Build"
4. Click build number → "Console Output"
5. Wait for all stages to complete (✅)
6. SSH to VM and run: docker compose ps
```

## Common Commands

**View build logs:**
```
Jenkins UI → Job → Build #N → Console Output
```

**SSH to VM and check status:**
```bash
ssh ubuntu@your-vm-ip
docker compose ps
docker compose logs backend
docker compose logs frontend
```

**Manually deploy on VM (for testing):**
```bash
cd /home/ubuntu/crud-dd-task-mean-app
docker login -u priyadarshankhavtode
docker compose pull
docker compose up -d --remove-orphans
```

## Credential Setup Quick Checklist

### Docker Hub Credential

- [ ] Jenkins: Manage Jenkins → Credentials → + Add Credentials
- [ ] Kind: Username with password
- [ ] ID: `dockerhub-creds`
- [ ] Username: `priyadarshankhavtode`
- [ ] Password: (your Docker Hub password or PAT)

### SSH Credential

- [ ] Generate SSH key: `ssh-keygen -t rsa -b 4096 -f ~/.ssh/jenkins_deploy -N ""`
- [ ] Add public key to VM: `ssh-copy-id -i ~/.ssh/jenkins_deploy.pub ubuntu@your-vm-ip`
- [ ] Jenkins: Manage Jenkins → Credentials → + Add Credentials
- [ ] Kind: SSH Username with private key
- [ ] ID: `deploy-ssh-key`
- [ ] Username: `ubuntu`
- [ ] Private Key: (paste contents of `~/.ssh/jenkins_deploy`)

## Need Help?

- **Build fails:** Check Console Output for error messages
- **SSH connection fails:** Verify VM is reachable and SSH key is authorized
- **Docker Hub error:** Verify credentials and check if image push succeeded
- **Services not starting on VM:** SSH to VM, run `docker compose logs`, check for errors

---

For detailed setup instructions, see `JENKINS_SETUP.md`.
