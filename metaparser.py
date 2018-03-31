#!/usr/bin/python

import os
import re
import glob
import argparse
import datetime
import json

import dsm

from dateutil.parser import parse

metatag_re = re.compile(r'@([a-zA-Z0-9]+)\s*:\s*"?([^"^\s]+)"?')
category_re = re.compile(r'^\s*string\s*Category\s*=\s*"([^"]+)"')
subcategory_re = re.compile(r'^\s*string\s*SubCategory\s*=\s*"([^"]+)"')
description_re = re.compile(r'^\s*string\s*Description\s*=\s*"([^"]+)"')


def string_attr(value):
    return value


def date_attr(value):
    return parse(value).isoformat()


def url_attr(value):
    return value


def one(parser):
    def wrap(metadata, attr, value):
        metadata[attr] = parser(value)
    return wrap


def multiple(parser):
    def wrap(metadata, attr, value):
        metadata.setdefault(attr, [])
        metadata[attr].append(parser(value))
    return wrap


SUPPORTED_ATTRS = {
        'author': one(string_attr),
        'maintainer': multiple(string_attr),
        'name': one(string_attr),
        'license': one(string_attr),
        'releasedate': one(date_attr),
        'video': multiple(url_attr),
        'picture': multiple(url_attr),
        }


def readlines(path):
    encodings = ['latin1', 'utf-8']

    for encoding in encodings:
        try:
            with open(path, encoding=encoding) as fh:
                return fh.readlines()
        except UnicodeDecodeError:
            continue

    raise UnicodeDecodeError('Unhandled file encoding')


def metadata_parser(metadata, line):
    result = metatag_re.findall(line)
    if result:
        attr, value = result[0]
        try:
            updater = SUPPORTED_ATTRS[attr]
        except KeyError:
            print("Unknown attr: `%s`. Skipping.", attr)
        else:
            updater(metadata, attr, value)
            return True


def simple_regexp_parser_factory(attr, regexp):
    def simple_regexp_parser(metadata, line):
        result = regexp.findall(line)
        if result:
            metadata[attr] = result[0]
            return True
    return simple_regexp_parser


class CommentsExtractorMachine(dsm.StateMachine):
    class Meta:
        initial = 'no-comment'
        transitions = (
            ('no-comment', '/', 'maybe-comment'),
            ('maybe-comment', '*', 'multiline-comment'),
            ('maybe-comment', '/', 'singleline-comment'),
            ('multiline-comment', '*', 'maybe-end-multiline-comment'),
            ('maybe-end-multiline-comment', '/', 'no-comment'),
            ('singleline-comment', '\n', 'no-comment'),
        )
        fallbacks = (
            ('no-comment', 'no-comment'),
            ('maybe-comment', 'no-comment'),
            ('maybe-end-multiline-comment', 'no-comment'),
            ('multiline-comment', 'multiline-comment'),
            ('singleline-comment', 'singleline-comment'),
        )


def extract_comments(lines):
    content = ''.join(lines)

    comments_found = []
    new_comment = []

    def store_new_comment(state, previous):
        if state == 'no-comment' and new_comment:
            if previous == 'singleline-comment':
                comments_found.append(''.join(new_comment[1:]))
            if previous == 'multiline-comment':
                comments_found.append(''.join(new_comment[1:-1]))
            new_comment.clear()

    fsm = CommentsExtractorMachine()
    fsm.when('multiline-comment', new_comment.append)
    fsm.when('singleline-comment', new_comment.append)
    fsm._eventhandler.on('change', store_new_comment)
    fsm.process_many(content)

    return comments_found


def extract_metadata(path):
    filename = os.path.basename(path)

    metadata = {
            'name': os.path.splitext(filename)[0],
            'filename': filename,
        }

    parsers = (
            metadata_parser,
            simple_regexp_parser_factory('category', category_re),
            simple_regexp_parser_factory('subcategory', subcategory_re),
            simple_regexp_parser_factory('name', description_re),
            )

    lines = readlines(path)

    # extract comments and transform into description
    comments = extract_comments(lines)
    description = '\n'.join(comments)

    def is_not_comment_line(x):
        return not (x.startswith('---') and (
                x.endswith('-//') or x.endswith('---'))) or (
            x.startswith('//') and x.endswith('//'))

    # strip out comment-like lines from description
    description = '\n'.join(
            filter(is_not_comment_line, description.split('\n')))

    if description:
        metadata['description'] = description

    for line in lines:
        for parser in parsers:
            if parser(metadata, line):
                break

    return metadata


def find_files(search_dir):
    path = os.path.abspath(os.path.expanduser(search_dir))
    return glob.glob('%s/**/*.fx' % path, recursive=True)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('search_dir', default='.')

    opts = parser.parse_args()
    paths = find_files(opts.search_dir)
    effects = []
    for path in paths:
        effects.append(extract_metadata(path))
    print(json.dumps({
        'items': effects,
        'count': len(effects),
        'date': datetime.datetime.now().isoformat(),
        }))


if __name__ == '__main__':
    main()
