#!/bin/bash
aws ecr batch-delete-image --region us-west-2 --repository-name flaskapp   --image-ids "$(aws ecr list-images --region us-west-2 --repository-name flaspapp --query 'imageIds[*]' --output json)"
terraform destroy