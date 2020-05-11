const fs = require('fs')
const path = require('path')
const toc = require('markdown-toc');

//conf
const folderPath = 'docs'
const isFile = fileName => { return fs.lstatSync(fileName).isFile() }

//get index of all files in docs folder
var files = fs.readdirSync(folderPath).map(fileName => {
    return path.join(folderPath, fileName)
}).filter(isFile);

//iterate over all files
files.forEach(function (file, index) {
    fs.writeFileSync(
        file,
        toc.insert(
            fs.readFileSync(file, 'utf8'),
            {maxdepth: 2, bullets: '-'}
        )
    );
});
