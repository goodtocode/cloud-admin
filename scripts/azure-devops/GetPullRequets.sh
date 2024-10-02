
#!/bin/bash
# Set your organization URL
ORG_URL="https://dev.azure.com/ORGANIZATION"

# authenticate
az extension add --name azure-devops
az login
az devops configure --defaults organization=$ORG_URL

# Get all projects
projects=$(az devops project list --organization $ORG_URL --query "value[].name" -o tsv)

# Loop through each project
for project in $projects; do
  echo "Project: $project"
  
  # Get all repositories in the project
  repos=$(az repos list --project $project --organization $ORG_URL --query "[].name" -o tsv)
  
  # Loop through each repository
  for repo in $repos; do
    echo "  Repository: $repo"
    
    # List all pull requests in the repository
    az repos pr list --repository $repo --project $project --organization $ORG_URL --status all
  done
done
