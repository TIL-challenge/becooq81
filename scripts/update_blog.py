import feedparser
import git
import os
import hashlib
import json
from git.exc import GitCommandError
from googletrans import Translator

# Initialize the Google Translate API
translator = Translator()

# Velog RSS feed URL
rss_url = 'https://api.velog.io/rss/@becooq81'

# GitHub repository path
repo_path = '.'

# 'velog-posts' directory path
posts_dir = os.path.join(repo_path, 'velog-posts')

# File to store processed content hashes
hash_file_path = os.path.join(repo_path, 'processed_hashes.json')

# Create 'velog-posts' if the directory does not exist
if not os.path.exists(posts_dir):
    os.makedirs(posts_dir)

# Load the repository
repo = git.Repo(repo_path)

# Double-check Git configuration
repo.git.config('--global', 'user.name', 'github-actions[bot]')
repo.git.config('--global', 'user.email', 'github-actions[bot]@users.noreply.github.com')

# Parse RSS feed
feed = feedparser.parse(rss_url)

# Define method to process titles
def process_title(title):
    title = title.replace('/', '-').replace('\\', '-').replace(' ', '-').replace('.', '').replace(',', '')
    title += '.md'
    return title

# Define method to create a unique identifier for content
def generate_content_hash(content):
    return hashlib.md5(content.encode('utf-8')).hexdigest()

# Load the processed hashes from file if it exists
if os.path.exists(hash_file_path):
    with open(hash_file_path, 'r', encoding='utf-8') as hash_file:
        processed_hashes = json.load(hash_file)
else:
    processed_hashes = {}

# Save each post as a file and commit
for entry in feed.entries:
    
    # Detect the language of the title
    detected_language = translator.detect(entry.title).lang
    
    # Translate title to English if the detected language is Korean
    translated_title = entry.title
    if detected_language == 'ko':
        translated_title = translator.translate(entry.title, src='ko', dest='en').text

    # Process translated title to create a valid filename
    translated_name = process_title(translated_title)
    
    # Create file path using the translated title
    file_path = os.path.join(posts_dir, translated_name)
    
    # Generate a hash of the original content
    content_hash = generate_content_hash(entry.description)

    # Check if this content hash has already been processed
    if content_hash in processed_hashes:
        print(f"Skipping already processed post: {entry.title}")
        continue
    
    # If content is new, mark it as processed
    processed_hashes[content_hash] = translated_name

    # Check if the file exists and if its content has changed
    content_changed = True
    new_content = entry.description
    if os.path.exists(file_path):
        with open(file_path, 'r', encoding='utf-8') as file:
            existing_content = file.read()
        if existing_content == new_content:
            content_changed = False
    
    # Create or overwrite the file only if content has changed
    if content_changed:
        with open(file_path, 'w', encoding='utf-8') as file:
            file.write(new_content)

        # Stage and commit the changes
        repo.git.add(file_path)
        try:
            repo.git.commit('-m', f'Add or update post: {translated_name}')
        except GitCommandError as e:
            print(f"Failed to commit: {e}")

# Fetch, rebase, and push changes to the repository
try:
    # Fetch and rebase to ensure the local branch is up to date
    print("Fetching latest changes...")
    repo.git.fetch('origin', 'main')
    print("Rebasing local changes...")
    repo.git.rebase('origin/main')

    # Push changes
    print("Pushing changes to remote...")
    repo.git.push()
except GitCommandError as e:
    print(f"Git command failed: {e}")
    if 'Updates were rejected' in str(e):
        print("Rebase failed due to remote changes. Attempting to resolve.")
        try:
            repo.git.rebase('--abort')  # Abort if there's an ongoing rebase
            repo.git.pull('--rebase')  # Pull and rebase again
            print("Rebasing completed. Retrying push...")
            repo.git.push()
        except GitCommandError as push_error:
            print(f"Push failed after resolving: {push_error}")
            print("Manual intervention may be required.")

# Save the updated processed hashes to file
with open(hash_file_path, 'w', encoding='utf-8') as hash_file:
    json.dump(processed_hashes, hash_file, ensure_ascii=False, indent=4)
