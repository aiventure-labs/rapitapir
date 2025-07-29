# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RapiTapir::Auth::Context do
  describe '#initialize' do
    it 'creates an empty context by default' do
      context = described_class.new
      
      expect(context.user).to be_nil
      expect(context.scopes).to be_empty
      expect(context.token).to be_nil
      expect(context.session).to be_empty
      expect(context.metadata).to be_empty
    end

    it 'creates a context with provided data' do
      user = { id: 123, name: 'Test User' }
      scopes = ['read', 'write']
      token = 'abc123'
      session = { session_id: 'sess_123' }
      metadata = { ip: '127.0.0.1' }

      context = described_class.new(
        user: user,
        scopes: scopes,
        token: token,
        session: session,
        metadata: metadata
      )

      expect(context.user).to eq(user)
      expect(context.scopes).to eq(scopes)
      expect(context.token).to eq(token)
      expect(context.session).to eq(session)
      expect(context.metadata).to eq(metadata)
    end
  end

  describe '#authenticated?' do
    it 'returns false when user is nil' do
      context = described_class.new
      expect(context).not_to be_authenticated
    end

    it 'returns true when user is present' do
      context = described_class.new(user: { id: 123 })
      expect(context).to be_authenticated
    end
  end

  describe '#has_scope?' do
    let(:context) { described_class.new(scopes: ['read', 'write']) }

    it 'returns true for existing scope' do
      expect(context.has_scope?('read')).to be true
      expect(context.has_scope?(:read)).to be true
    end

    it 'returns false for non-existing scope' do
      expect(context.has_scope?('admin')).to be false
    end
  end

  describe '#has_any_scope?' do
    let(:context) { described_class.new(scopes: ['read', 'write']) }

    it 'returns true if any scope matches' do
      expect(context.has_any_scope?('read', 'admin')).to be true
    end

    it 'returns false if no scopes match' do
      expect(context.has_any_scope?('admin', 'delete')).to be false
    end
  end

  describe '#has_all_scopes?' do
    let(:context) { described_class.new(scopes: ['read', 'write']) }

    it 'returns true if all scopes match' do
      expect(context.has_all_scopes?('read', 'write')).to be true
    end

    it 'returns false if not all scopes match' do
      expect(context.has_all_scopes?('read', 'admin')).to be false
    end
  end

  describe '#user_id' do
    it 'returns nil when user is nil' do
      context = described_class.new
      expect(context.user_id).to be_nil
    end

    it 'extracts id from hash user' do
      context = described_class.new(user: { id: 123, name: 'Test' })
      expect(context.user_id).to eq(123)
    end

    it 'extracts string key id from hash user' do
      context = described_class.new(user: { 'id' => 456, 'name' => 'Test' })
      expect(context.user_id).to eq(456)
    end

    it 'returns user directly if it is a string or number' do
      context = described_class.new(user: 'user123')
      expect(context.user_id).to eq('user123')

      context = described_class.new(user: 789)
      expect(context.user_id).to eq(789)
    end

    it 'calls id method on object user' do
      user = double('User', id: 999)
      context = described_class.new(user: user)
      expect(context.user_id).to eq(999)
    end
  end

  describe '#add_scope' do
    let(:context) { described_class.new(scopes: ['read']) }

    it 'adds a new scope' do
      context.add_scope('write')
      expect(context.scopes).to include('write')
    end

    it 'does not add duplicate scopes' do
      context.add_scope('read')
      expect(context.scopes.count('read')).to eq(1)
    end
  end

  describe '#remove_scope' do
    let(:context) { described_class.new(scopes: ['read', 'write']) }

    it 'removes an existing scope' do
      context.remove_scope('read')
      expect(context.scopes).not_to include('read')
      expect(context.scopes).to include('write')
    end
  end

  describe '#merge' do
    it 'merges two contexts' do
      context1 = described_class.new(
        user: { id: 1 },
        scopes: ['read'],
        session: { key1: 'value1' },
        metadata: { ip: '127.0.0.1' }
      )

      context2 = described_class.new(
        user: { id: 2 },
        scopes: ['write'],
        session: { key2: 'value2' },
        metadata: { agent: 'test' }
      )

      merged = context1.merge(context2)

      expect(merged.user).to eq({ id: 2 })
      expect(merged.scopes).to contain_exactly('read', 'write')
      expect(merged.session).to eq({ key1: 'value1', key2: 'value2' })
      expect(merged.metadata).to eq({ ip: '127.0.0.1', agent: 'test' })
    end
  end

  describe '#to_hash' do
    it 'converts context to hash' do
      user = { id: 123, name: 'Test' }
      context = described_class.new(
        user: user,
        scopes: ['read'],
        token: 'abc123'
      )

      hash = context.to_hash

      expect(hash).to include(
        user: user,
        scopes: ['read'],
        token: 'abc123',
        authenticated: true,
        user_id: 123
      )
    end
  end
end

RSpec.describe RapiTapir::Auth::ContextStore do
  after(:each) do
    described_class.clear
  end

  describe '.current' do
    it 'returns nil when no context is set' do
      expect(described_class.current).to be_nil
    end

    it 'returns the current context' do
      context = RapiTapir::Auth::Context.new(user: { id: 123 })
      described_class.current = context
      expect(described_class.current).to eq(context)
    end
  end

  describe '.with_context' do
    it 'temporarily sets context for block execution' do
      context = RapiTapir::Auth::Context.new(user: { id: 123 })
      result = nil

      described_class.with_context(context) do
        result = described_class.current
      end

      expect(result).to eq(context)
      expect(described_class.current).to be_nil
    end

    it 'restores previous context after block execution' do
      original_context = RapiTapir::Auth::Context.new(user: { id: 1 })
      new_context = RapiTapir::Auth::Context.new(user: { id: 2 })

      described_class.current = original_context

      described_class.with_context(new_context) do
        expect(described_class.current).to eq(new_context)
      end

      expect(described_class.current).to eq(original_context)
    end
  end

  describe '.clear' do
    it 'clears the current context' do
      context = RapiTapir::Auth::Context.new(user: { id: 123 })
      described_class.current = context
      
      described_class.clear
      
      expect(described_class.current).to be_nil
    end
  end
end
