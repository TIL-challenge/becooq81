name: Update Commit Activity Badge

on:
  schedule:
    - cron: '0 0 * * 0'  # Runs weekly on Sunday
  workflow_dispatch:  # Allows manual run

jobs:
  update-commit-badge:
    runs-on: ubuntu-latest

    steps:
      - name: Checkout Repo
        uses: actions/checkout@v2
        with:
          ref: main  # Make sure this matches your working branch
          persist-credentials: true  # Ensure GitHub token is used

      - name: Setup Git Config
        run: |
          git config --global user.email "github-actions[bot]@github.com"
          git config --global user.name "github-actions[bot]"

      - name: Count Commit Days
        id: count_days
        run: |
          # Count unique commit days
          days=$(git log --since='7 days ago' --format='%cd' --date=format:'%A' | sort -u | wc -l)
          echo "Commit days found: $days"
          echo "commit_days=$days" >> $GITHUB_ENV
          echo "::set-output name=commit_days::$days"

      - name: Create Badge
        run: |
          # Create badge with cache-busting parameter
          badge_url="https://img.shields.io/badge/commit_days-${{ env.commit_days }}-green?cache=$(date +%s)"
          echo "Badge URL: $badge_url"
          echo "![Commit Days]($badge_url)" > commit_badge.md

      - name: Update README with Badge
        run: |
          # Replace the old badge line in README.md
          sed -i '/Commit Days/d' README.md  # Remove old badge line if exists
          echo "![Commit Days]($badge_url)" >> README.md  # Add the new badge

      - name: Commit Changes
        run: |
          git add README.md
          git commit -m "Update commit days badge"
          git push
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
