const fs = require('fs');
const content = fs.readFileSync('/Users/sandeepvarikuppala/Downloads/My tasks/Clothing Flutter App/lib/features/home/screens/home_screen.dart', 'utf8');
const lines = content.split(/\r?\n/);
for (let i = 3485; i <= 3505; i++) {
  const line = lines[i];
  console.log(`${i + 1}: [${line}] (${JSON.stringify(line)})`);
}
