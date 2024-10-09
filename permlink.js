import { mkdirSync } from 'node:fs'

const file = Bun.file('./output/forest.json')
const output = await file.text()
const all_trees = JSON.parse(output)
const index_html = await Bun.file('./assets/index.html').text()

for (const [tree_id, tree] of Object.entries(all_trees)) {
    if (tree.metas) {
        // console.log(tree_id, tree.metas);
        if (tree.metas.permlink) {
            const permlink = tree.metas.permlink
            console.log(tree_id, permlink)
            mkdirSync(`./output/${permlink}`, { recursive: true })
            await Bun.write(
                `./output/${permlink}/index.html`,
                index_html.replaceAll('./index.xml', `../${tree_id}.xml`),
            )
        }
    }
}
