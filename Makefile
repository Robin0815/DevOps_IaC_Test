.PHONY: help start stop restart status logs clean setup-monitoring

# Default target
help:
	@echo "Local CI/CD Pipeline Management"
	@echo ""
	@echo "Available commands:"
	@echo "  start              - Start all services"
	@echo "  start-monitoring   - Start with monitoring (Prometheus + Grafana)"
	@echo "  stop               - Stop all services"
	@echo "  restart            - Restart all services"
	@echo "  status             - Show service status and URLs"
	@echo "  logs               - Show logs for all services"
	@echo "  logs-follow        - Follow logs for all services"
	@echo "  clean              - Stop and remove all containers and volumes"
	@echo "  setup              - Initial setup and configuration"
	@echo "  backup             - Backup all data"
	@echo "  restore            - Restore from backup"

# Start services
start:
	@echo "Starting CI/CD Pipeline..."
	@mkdir -p config data/forgejo data/runner data/argocd data/registry data/prometheus data/grafana
	@cp -n config/prometheus.yml.example config/prometheus.yml 2>/dev/null || true
	docker-compose up -d
	@echo "Services starting... Use 'make status' to check when ready"

# Start with monitoring
start-monitoring:
	@echo "Starting CI/CD Pipeline with monitoring..."
	@mkdir -p config data/forgejo data/runner data/argocd data/registry data/prometheus data/grafana
	@cp -n config/prometheus.yml.example config/prometheus.yml 2>/dev/null || true
	docker-compose --profile monitoring up -d
	@echo "Services starting... Use 'make status' to check when ready"

# Stop services
stop:
	@echo "Stopping CI/CD Pipeline..."
	docker-compose down

# Restart services
restart: stop start

# Show status
status:
	@echo "=== Service Status ==="
	@docker-compose ps
	@echo ""
	@echo "=== Service URLs ==="
	@echo "Forgejo:    http://localhost:3000"
	@echo "ArgoCD:     http://localhost:8080"
	@echo "Registry:   http://localhost:5000"
	@echo "Prometheus: http://localhost:9090 (if monitoring enabled)"
	@echo "Grafana:    http://localhost:3001 (if monitoring enabled)"
	@echo ""
	@echo "=== Default Credentials ==="
	@echo "ArgoCD:  admin / (get password with: make argocd-password)"
	@echo "Grafana: admin / admin"

# Show logs
logs:
	docker-compose logs

# Follow logs
logs-follow:
	docker-compose logs -f

# Clean everything
clean:
	@echo "Cleaning up CI/CD Pipeline..."
	@read -p "This will remove all containers and data. Continue? [y/N] " confirm && [ "$$confirm" = "y" ]
	docker-compose down
	docker-compose rm -f
	@echo "Removing data directory..."
	rm -rf data/

# Initial setup
setup:
	@echo "Setting up CI/CD Pipeline..."
	@mkdir -p config docs examples data/forgejo data/runner data/argocd data/registry data/prometheus data/grafana
	@echo "Creating configuration files..."
	@make _create-configs
	@echo "Setup complete! Run 'make start' to begin"

# Get ArgoCD password
argocd-password:
	@docker exec argocd-server argocd admin initial-password -n 2>/dev/null || echo "ArgoCD not ready yet"

# Backup data
backup:
	@echo "Creating backup..."
	@mkdir -p backups
	@tar czf backups/forgejo-$(shell date +%Y%m%d-%H%M%S).tar.gz -C data forgejo
	@tar czf backups/argocd-$(shell date +%Y%m%d-%H%M%S).tar.gz -C data argocd
	@tar czf backups/registry-$(shell date +%Y%m%d-%H%M%S).tar.gz -C data registry
	@echo "Backup completed in ./backups/"

# Internal target to create config files
_create-configs:
	@echo 'global:\n  scrape_interval: 15s\nscrape_configs:\n  - job_name: "prometheus"\n    static_configs:\n      - targets: ["localhost:9090"]' > config/prometheus.yml.example