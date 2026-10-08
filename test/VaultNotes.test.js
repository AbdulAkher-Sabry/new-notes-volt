/**
 * @vitest-environment jsdom
 */
import { describe, it, expect, beforeEach } from 'vitest';
import { VaultNotes } from '../src/VaultNotes';

describe('VaultNotes', () => {
  let container;

  beforeEach(() => {
    // Set up DOM
    document.body.innerHTML = '<div id="editor-container"></div>';
    container = document.getElementById('editor-container');

    // Mock getSelection which is used by Quill
    document.getSelection = () => ({
      getRangeAt: () => ({}),
    });
  });

  it('should initialize Quill editor in the container', () => {
    const notes = new VaultNotes('editor-container');
    expect(notes.quill).toBeDefined();
    expect(container.querySelector('.ql-editor')).toBeDefined();
  });

  it('should throw an error if container is not found', () => {
    expect(() => new VaultNotes('non-existent')).toThrow(/not found/);
  });

  it('should get plain text content', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('Hello World\n');
    expect(notes.getText()).toBe('Hello World\n');
  });

  it('should get HTML content', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.root.innerHTML = '<p>Hello <strong>World</strong></p>';
    expect(notes.getHTML()).toBe('<p>Hello <strong>World</strong></p>');
  });

  it('should extract single tag correctly', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('This is a #test note\n');
    const tags = notes.extractTags();
    expect(tags).toEqual(['test']);
  });

  it('should extract multiple unique tags correctly', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('This is a #test note with #multiple #tags and another #test\n');
    const tags = notes.extractTags();
    // Verify it extracts all tags, without hashes, and removes duplicates
    expect(tags).toEqual(['test', 'multiple', 'tags']);
  });

  it('should handle tags with hyphens or underscores', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('Tag with #hyphen-tag and #underscore_tag\n');
    const tags = notes.extractTags();
    expect(tags).toEqual(['hyphen-tag', 'underscore_tag']);
  });

  it('should not match hashes in middle of words', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('Not a tag like word#not-a-tag\n');
    const tags = notes.extractTags();
    expect(tags).toEqual([]);
  });

  it('should return empty array if no tags', () => {
    const notes = new VaultNotes('editor-container');
    notes.quill.setText('No tags here\n');
    expect(notes.extractTags()).toEqual([]);
  });
});
