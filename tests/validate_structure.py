"""Author-only checks. Runtime Skills and helpers do not require Python."""
import argparse
import json
import re
from pathlib import Path
import yaml


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path('.'))
    parser.add_argument('--schema', type=Path)
    parser.add_argument('--report', type=Path)
    args = parser.parse_args()
    root = args.root.resolve()
    checks = []

    def check(name, condition, detail=''):
        checks.append({'name': name, 'passed': bool(condition), 'detail': str(detail)})

    def read_json(relative):
        return json.loads((root / relative).read_text(encoding='utf-8-sig'))

    portable = read_json('plugin.json')
    legacy = read_json('.codex-plugin/plugin.json')
    market = read_json('.agents/plugins/marketplace.json')
    for key in ['name', 'version', 'description', 'author']:
        check('manifest:' + key, portable[key] == legacy[key])
    interface = portable['extensions']['com.openai']['interface']
    check('manifest:presentation', interface == legacy['interface'])
    check('manifest:short_description', len(interface['shortDescription']) <= 30)
    check('manifest:skills_only', not (set(portable) & {'skills', 'mcpServers', 'apps', 'interface'}))
    check('manifest:semver', re.fullmatch(r'\d+\.\d+\.\d+', portable['version']))
    check('marketplace:local', market['plugins'][0]['name'] == portable['name'] and market['plugins'][0]['source'] == {'source': 'local', 'path': './'})
    for host, relative in [('claude', '.claude-plugin/plugin.json'), ('cursor', '.cursor-plugin/plugin.json'), ('gemini', 'gemini-extension.json')]:
        manifest = read_json(relative)
        for key in ['name', 'version', 'description']:
            check(host + ':manifest:' + key, manifest[key] == portable[key])
        if host != 'gemini':
            check(host + ':author', manifest['author'] == portable['author'])
            check(host + ':license', manifest['license'] == 'MIT')
        # All hosts discover skills/ by default; no server or executable adapter is needed.
        check(host + ':native_skills_only', not (set(manifest) & {'skills', 'mcpServers', 'hooks', 'dependencies'}))
    if args.schema:
        import jsonschema
        try:
            jsonschema.validate(portable, json.loads(args.schema.read_text(encoding='utf-8-sig')))
            check('official_schema', True)
        except jsonschema.ValidationError as exc:
            check('official_schema', False, exc.message)

    capabilities = read_json('docs/capabilities.json')['capabilities']
    names = {p.parent.name for p in (root / 'skills').glob('*/SKILL.md')}
    check('skills:nonempty', bool(names))
    check('capabilities:coverage', {c['id'] for c in capabilities} == names)
    check('capabilities:unique', len({c['id'] for c in capabilities}) == len(capabilities))
    case_manifest = read_json('tests/cases.json')
    declared_cases = {item['id'] for section in ('cases', 'integration_suites') for item in case_manifest.get(section, [])}
    check('cases:skill_coverage', {item.get('skill') for item in case_manifest['cases'] if item.get('skill')} == names)
    for capability in capabilities:
        check(capability['id'] + ':test_references', bool(capability.get('test_ids')) and all(value in declared_cases for value in capability['test_ids']))
        for relative in [capability['skill'], capability['example'], capability['evidence']] + capability.get('recipe_references', []):
            resolved = (root / relative).resolve()
            check(capability['id'] + ':capability_reference:' + relative, resolved.is_relative_to(root) and resolved.is_file())
    for item in case_manifest['cases']:
        if item.get('skill'):
            check(item['id'] + ':capability_id', item.get('capability_id') == item['skill'])
    for name in sorted(names):
        base = root / 'skills' / name
        text = (base / 'SKILL.md').read_text(encoding='utf-8')
        match = re.match(r'^---\n(.*?)\n---\n', text, re.S)
        front = yaml.safe_load(match.group(1)) if match else {}
        check(name + ':frontmatter', front.get('name') == name and isinstance(front.get('description'), str) and 10 < len(front['description']) < 1024)
        ui = yaml.safe_load((base / 'agents/openai.yaml').read_text(encoding='utf-8'))
        check(name + ':prompt', '$' + name in ui['interface']['default_prompt'])
        check(name + ':ui_description', 25 <= len(ui['interface']['short_description']) <= 64)
        check(name + ':implicit', ui['policy']['allow_implicit_invocation'] is True)
        check(name + ':sections', all(x in text for x in ['## Purpose and Scope', '## Prerequisite Checks', '## Workflow and Key Decisions', '## File Changes, Saving, and Recovery', '## Acceptance and Delivery', '## On-Demand References and Examples']))
        native = (base / 'references/native.md').read_text(encoding='utf-8')
        check(name + ':references', 'https://docs.godotengine.org/en/4.7/' in native and 'https://github.com/godotengine/godot/' in native)
        check(name + ':runnable', all((base / 'assets/examples/minimal' / p).is_file() for p in ['example.gd', 'project.godot']))
    route = read_json('tests/routing/prompts.json') if (root / 'tests/routing/prompts.json').exists() else []
    if route:
        check('routing:coverage', {c['skill'] for c in route} == names)
        for item in route:
            check(item['skill'] + ':routing', item['positive_expected'] == item['skill'] and item['negative_expected'] != item['skill'] and item['adjacent_expected'] in names and bool(item['adjacent_prompt']))

    published = [root / name for name in ['README.md', 'README.zh.md', 'CHANGELOG.md', 'CHANGELOG.zh.md', 'CONTRIBUTING.md', 'CONTRIBUTING.zh.md']]
    # Public guides and top-level reports are paired; research archives retain their original language.
    published.extend((root / 'assets').glob('*.md'))
    paired_docs = published + list((root / 'docs').glob('*.md'))
    for path in paired_docs:
        counterpart = path.with_name(path.name[:-6] + '.md' if path.name.endswith('.zh.md') else path.stem + '.zh.md')
        check(str(path.relative_to(root)) + ':language_pair', counterpart.is_file())
        check(str(path.relative_to(root)) + ':language_switch', '](' + counterpart.name + ')' in path.read_text(encoding='utf-8'))
    changelog = (root / 'CHANGELOG.md').read_text(encoding='utf-8')
    check('changelog:current_version', '## [' + portable['version'] + ']' in changelog)
    for filename, other in [('README.md', 'README.zh.md'), ('README.zh.md', 'README.md')]:
        text = (root / filename).read_text(encoding='utf-8')
        check(filename + ':language_switch', '](' + other + ')' in text)
        check(filename + ':hosts', all(host in text for host in ['Codex Desktop', 'Codex CLI', 'Claude Code', 'Cursor', 'Gemini CLI']))
        check(filename + ':skills', all('skills/' + name + '/SKILL.md' in text for name in names))
    for directory in ['skills', 'shared', 'docs']:
        published.extend((root / directory).rglob('*.md'))
    for path in published:
        text = path.read_text(encoding='utf-8')
        check(str(path.relative_to(root)) + ':no_placeholder', not re.search(r'\b(TODO|FIXME|TBD)\b', text))
        for target in re.findall(r'\[[^\]]*\]\(([^)]+)\)', text):
            if '://' in target or target.startswith('#'):
                continue
            target = target.split('#')[0].strip('<>')
            resolved = (path.parent / target).resolve()
            check(str(path.relative_to(root)) + ':link:' + target, resolved.is_relative_to(root) and resolved.exists())
    for directory in ['skills', 'shared', 'docs']:
        for path in (root / directory).rglob('*'):
            if '.godot' in path.parts or '.godot-plugin' in path.parts:
                continue
            check('not_symlink:' + str(path.relative_to(root)), not path.is_symlink())
            if path.is_file() and path.suffix in {'.gd', '.md', '.json', '.yaml'}:
                check('portable:' + str(path.relative_to(root)), 'E:/repos/godot-plugin' not in path.read_text(encoding='utf-8'))
    result = {'status': 'passed' if all(x['passed'] for x in checks) else 'failed', 'checks': checks}
    if args.report:
        args.report.parent.mkdir(parents=True, exist_ok=True)
        args.report.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding='utf-8')
    print(json.dumps({'status': result['status'], 'checks': len(checks), 'failures': [x for x in checks if not x['passed']]}, ensure_ascii=False, indent=2))
    raise SystemExit(0 if result['status'] == 'passed' else 1)


if __name__ == '__main__':
    main()
