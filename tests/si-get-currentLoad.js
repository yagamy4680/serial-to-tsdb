#!/usr/bin/env node
'use strict';
var si = require('systeminformation');
var index = 0;
const token = '%';
const group = 'currentLoad';
const type = 'systeminformation';
const subtype = 'currentLoad';

si.system().then(sys => {
    var {manufacturer, serial} = sys;

    setInterval(() => {
        si.currentLoad().then(data => {
            var tokens = [token, `${index++}`, group, `type:${type}`, `subtype:${subtype}`, `serial:${serial}`];
            tokens.push(`load=${data.currentLoad}`);
            tokens.push(`user=${data.currentLoadUser}`);
            tokens.push(`system=${data.currentLoadSystem}`);
            tokens.push(`nice=${data.currentLoadNice}`);
            tokens.push(`idle=${data.currentLoadIdle}`);
            console.log(tokens.join('\t'));
        });
    }, 500);    
});
