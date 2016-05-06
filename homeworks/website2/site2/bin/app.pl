#!/usr/bin/env perl
use Dancer;
use site;
use Dancer::Plugin::RPC::XML;
use XML::RPC;
use Dancer::Plugin::Auth::Basic;
use Dancer::Session;
set session => 'YAML';
dance;
#change
