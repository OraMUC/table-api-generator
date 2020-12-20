var fs = require('fs');

fs.writeFileSync(
    'om_tapigen_install.sql',
    fs.readFileSync('src/om_tapigen_install.sql', 'utf8')
        .replace('@OM_TAPIGEN.pks', function(){return fs.readFileSync('src/OM_TAPIGEN.pks', 'utf8')})
        .replace('@OM_TAPIGEN.pkb', function(){return fs.readFileSync('src/OM_TAPIGEN.pkb', 'utf8')})
        .replace('@OM_TAPIGEN_ODDGEN_WRAPPER.pks', function(){return fs.readFileSync('src/OM_TAPIGEN_ODDGEN_WRAPPER.pks', 'utf8')})
        .replace('@OM_TAPIGEN_ODDGEN_WRAPPER.pkb', function(){return fs.readFileSync('src/OM_TAPIGEN_ODDGEN_WRAPPER.pkb', 'utf8')})
        // Read what this function thing is doing, without it we get wrong results.
        // We have dollar signs in our package body text - the last answer explains:
        // https://stackoverflow.com/questions/9423722/string-replace-weird-behavior-when-using-dollar-sign-as-replacement
);

fs.copyFileSync(
    'src/om_tapigen_uninstall.sql', 
    'om_tapigen_uninstall.sql'
);