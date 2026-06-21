# scripts/ecr-build-push.ps1

param(
    [string]$Region = "ap-south-1",
    [string]$Tag = "latest"
)

$ErrorActionPreference = "Stop"

$Services = @(
    "product-service",
    "order-service"
)

$ProjectRoot = Split-Path -Parent $PSScriptRoot

Write-Host "Getting AWS Account ID..."
$AccountId = aws sts get-caller-identity --query Account --output text

if (-not $AccountId) {
    Write-Error "Unable to get AWS Account ID. Please run aws configure first."
    exit 1
}

$Registry = "$AccountId.dkr.ecr.$Region.amazonaws.com"

Write-Host "AWS Account ID: $AccountId"
Write-Host "AWS Region: $Region"
Write-Host "ECR Registry: $Registry"

Write-Host "Logging in to ECR..."
aws ecr get-login-password --region $Region | docker login --username AWS --password-stdin $Registry

foreach ($Service in $Services) {

    $RepoName = $Service
    $ImageUri = "$Registry/$RepoName:$Tag"
    $ServicePath = Join-Path $ProjectRoot "services\$Service"

    Write-Host ""
    Write-Host "--------------------------------------"
    Write-Host "Processing service: $Service"
    Write-Host "Service path: $ServicePath"
    Write-Host "Image URI: $ImageUri"
    Write-Host "--------------------------------------"

    if (-not (Test-Path $ServicePath)) {
        Write-Error "Service path not found: $ServicePath"
        exit 1
    }

    Write-Host "Checking ECR repository: $RepoName"

    $repoExists = $true

    aws ecr describe-repositories `
        --repository-names $RepoName `
        --region $Region `
        *> $null

    if ($LASTEXITCODE -ne 0) {
        $repoExists = $false
    }

    if (-not $repoExists) {
        Write-Host "Repository not found. Creating ECR repository: $RepoName"

        aws ecr create-repository `
            --repository-name $RepoName `
            --region $Region `
            --image-scanning-configuration scanOnPush=true `
            --encryption-configuration encryptionType=AES256
    }
    else {
        Write-Host "Repository already exists: $RepoName"
    }

    Write-Host "Building Docker image: $RepoName:$Tag"

    docker build `
        -t "$RepoName:$Tag" `
        -t "$ImageUri" `
        "$ServicePath"

    Write-Host "Pushing image to ECR: $ImageUri"

    docker push "$ImageUri"

    Write-Host "$Service pushed successfully."
}

Write-Host ""
Write-Host "All Docker images pushed to ECR successfully."