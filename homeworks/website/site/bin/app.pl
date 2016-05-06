#!/usr/bin/env perl
use Dancer;
use site;
use Dancer::Plugin::RPC::XML;
use XML::RPC;
xmlrpc '/rpc' => sub {
	return "hello";
};
dance;
