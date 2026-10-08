import Quill from 'quill';

export class VaultNotes {
  constructor(containerId, options = {}) {
    this.container = document.getElementById(containerId);
    if (!this.container) {
      throw new Error(`Container with id "${containerId}" not found.`);
    }

    const defaultOptions = {
      theme: 'snow',
      modules: {
        toolbar: [
          [{ header: [1, 2, false] }],
          ['bold', 'italic', 'underline'],
          ['image', 'code-block']
        ]
      }
    };

    this.quill = new Quill(this.container, { ...defaultOptions, ...options });
  }

  getText() {
    return this.quill.getText();
  }

  getHTML() {
    return this.quill.root.innerHTML;
  }

  extractTags() {
    const text = this.getText();
    const tagRegex = /(?:^|\s)#([\w-]+)/g;
    const tags = new Set();
    let match;

    while ((match = tagRegex.exec(text)) !== null) {
      tags.add(match[1]);
    }

    return Array.from(tags);
  }
}
