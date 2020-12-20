const fs   = require('fs')
const glob = require('glob');
const toc  = require('markdown-toc');
const navRegex = /<!-- *nav *-->[\s\S]*?<!-- *navstop *-->/gi;
const renderNavigation = function (type) {
    var menu = '';
    const entries = [
        {top:true,  name:"Index",                                 file:"README.md"},
        {top:true,  name:"Changelog",                             file:"changelog.md"},
        {top:true,  name:"Getting Started",                       file:"getting-started.md"},
        {top:true,  name:"Parameters",                            file:"parameters.md"},
        {top:true,  name:"Bulk Processing",                       file:"bulk-processing.md"},
        {top:true,  name:"Example API",                           file:"example-api.md"},
        {top:true,  name:"SQL Developer Integration",             file:"sql-developer-integration.md"},
        {top:false, name:"Advanced: Bulk Processing Performance", file:"bulk-processing-performance.md"},
        {top:false, name:"Advanced: Example API Modifikation",    file:"example-modify-api.md"},
    ];
    entries.forEach(function (entry) {
        if (type === 'top' && entry.top){
            menu += '| [' + entry.name + '](' + entry.file + ')\n';
        }
        else if (type === 'index' && entry.file !== 'README.md') {
            menu += '- [' + entry.name + '](' + entry.file + ')\n';
        }
    });
    if (type === 'top') {
        menu = menu.substr(2); //delete first pipe character and space
    }
    return '<!-- nav -->\n\n' + menu + '\n<!-- navstop -->';
};

glob('docs/*.md', function (err, files) {
    if (err) throw err;
    files.forEach(function (file) {
        var content = fs.readFileSync(file, 'utf8');
        if (file === 'docs/README.md') {
            content = content.replace(navRegex, renderNavigation('index'));
        }
        else {
            content = content.replace(navRegex, renderNavigation('top'));
            content = toc.insert(content, {maxdepth: 2, bullets: '-'});
        }
        fs.writeFileSync(file, content);
    });
});


