const fs = require('fs');
const path = require('path');

/**
 * Creates a new dev log file in notes-star-cities/dev-logs/
 * Usage: npm run log [topic]
 */

const today = new Date().toISOString().split('T')[0];
const fileName = `${today}.md`;
const logDir = path.resolve(__dirname, '../dev-logs');
const filePath = path.join(logDir, fileName);

const template = `---
date: ${today}
---

## Developer Logs



## Agent Logs


`;

// Ensure the directory exists
if (!fs.existsSync(logDir)) {
  fs.mkdirSync(logDir, { recursive: true });
}

// Check if file already exists to avoid overwriting
if (fs.existsSync(filePath)) {
  console.error(`Error: File ${fileName} already exists.`);
  process.exit(1);
}

try {
  fs.writeFileSync(filePath, template, 'utf8');
  console.log(`Successfully created dev log: ${fileName}`);
} catch (error) {
  console.error('Error creating dev log:', error.message);
  process.exit(1);
}
