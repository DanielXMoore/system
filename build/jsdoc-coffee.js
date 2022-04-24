const CoffeeScript = require("coffeescript");

exports.handlers = {
  beforeParse(e) {
    if (/\.coffee$/.test(e.filename)) {
      e.source = CoffeeScript.compile(e.source, {
        bare: true,
        filename: e.filename,
      });

      // TODO: sourcemap line numbers

      //console.log(e.source)
    }
  }
}

const cwd = process.cwd()
const path = require("path")
const importRe = /import\("([^"]+)"\)/g
const sepRe = /\\/g

exports.astNodeVisitor = {

  visitNode: function (node, e, parser, currentSourceName) {
    if (node.type === "File") {
      if (node.comments) {
        // console.log(node.type, node.comments)

        node.comments.forEach((comment) => {
          comment.value = comment.value.replace(importRe, (im, resolvePath) => {
            const target = path.join(currentSourceName, resolvePath)
            const relative = path.relative(cwd, target).replace(sepRe, "/")
            // console.log(currentSourceName, resolvePath, relative, target)
            return `module:${relative}`
          })

        })

        // console.log(node.type, node.comments)
      }
    }
  }
}
