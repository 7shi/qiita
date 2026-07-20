import json
import os
import yaml

def remove_nulls(d):
    if isinstance(d, dict):
        return {k: remove_nulls(v) for k, v in d.items() if v is not None}
    elif isinstance(d, list):
        return [remove_nulls(v) for v in d]
    return d

def main():
    os.makedirs('items', exist_ok=True)
    
    for i in range(1, 4):
        filename = f'data/7shi-{i}.json'
        if not os.path.exists(filename):
            continue
            
        with open(filename, 'r', encoding='utf-8') as f:
            data = json.load(f)
            
        for item in data:
            item_id = item.get('id')
            if not item_id:
                continue
                
            # Remove body and rendered_body from front matter
            body = item.pop('body', '')
            item.pop('rendered_body', None)
            
            # Remove user field
            item.pop('user', None)
            
            # Remove null values
            item = remove_nulls(item)
            
            # Create YAML front matter
            frontmatter = yaml.dump(item, allow_unicode=True, default_flow_style=False, sort_keys=False)
            
            out_path = f'items/{item_id}.md'
            with open(out_path, 'w', encoding='utf-8') as out_f:
                out_f.write('---\n')
                out_f.write(frontmatter)
                out_f.write('---\n\n')
                out_f.write(body)
                
if __name__ == '__main__':
    main()
