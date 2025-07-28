# frozen_string_literal: true

require 'spec_helper'
require 'rapitapir/server/path_matcher'

RSpec.describe RapiTapir::Server::PathMatcher do
  describe '#initialize' do
    it 'creates a path matcher with pattern' do
      matcher = described_class.new('/users/:id')
      expect(matcher.path_pattern).to eq('/users/:id')
      expect(matcher.param_names).to eq(['id'])
    end

    it 'extracts multiple parameter names' do
      matcher = described_class.new('/users/:user_id/posts/:post_id')
      expect(matcher.param_names).to eq(['user_id', 'post_id'])
    end
  end

  describe '#match' do
    it 'matches simple path with parameter' do
      matcher = described_class.new('/users/:id')
      result = matcher.match('/users/123')
      
      expect(result).to eq({ id: '123' })
    end

    it 'matches path with multiple parameters' do
      matcher = described_class.new('/users/:user_id/posts/:post_id')
      result = matcher.match('/users/123/posts/456')
      
      expect(result).to eq({ user_id: '123', post_id: '456' })
    end

    it 'returns nil for non-matching path' do
      matcher = described_class.new('/users/:id')
      result = matcher.match('/posts/123')
      
      expect(result).to be_nil
    end

    it 'matches exact path without parameters' do
      matcher = described_class.new('/users')
      result = matcher.match('/users')
      
      expect(result).to eq({})
    end
  end

  describe '#matches?' do
    it 'returns true for matching path' do
      matcher = described_class.new('/users/:id')
      expect(matcher.matches?('/users/123')).to be true
    end

    it 'returns false for non-matching path' do
      matcher = described_class.new('/users/:id')
      expect(matcher.matches?('/posts/123')).to be false
    end
  end
end
