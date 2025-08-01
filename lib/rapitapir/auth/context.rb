# frozen_string_literal: true

module RapiTapir
  module Auth
    class Context
      attr_reader :user, :scopes, :token, :session, :metadata

      def initialize(user: nil, scopes: [], token: nil, session: {}, metadata: {})
        @user = user
        @scopes = Array(scopes)
        @token = token
        @session = session || {}
        @metadata = metadata || {}
      end

      def authenticated?
        !@user.nil?
      end

      def has_scope?(scope)
        @scopes.include?(scope.to_s)
      end

      def has_any_scope?(*scopes)
        scopes.any? { |scope| has_scope?(scope) }
      end

      def has_all_scopes?(*scopes)
        scopes.all? { |scope| has_scope?(scope) }
      end

      def user_id
        return nil unless @user

        case @user
        when Hash
          @user[:id] || @user['id']
        when Numeric, String
          @user
        else
          @user.respond_to?(:id) ? @user.id : @user.to_s
        end
      end

      def add_scope(scope)
        @scopes << scope.to_s unless has_scope?(scope)
      end

      def remove_scope(scope)
        @scopes.delete(scope.to_s)
      end

      def merge(other_context)
        Context.new(
          user: other_context.user || @user,
          scopes: (@scopes + other_context.scopes).uniq,
          token: other_context.token || @token,
          session: @session.merge(other_context.session),
          metadata: @metadata.merge(other_context.metadata)
        )
      end

      def to_hash
        {
          user: @user,
          scopes: @scopes,
          token: @token,
          session: @session,
          metadata: @metadata,
          authenticated: authenticated?,
          user_id: user_id
        }
      end

      def inspect
        "#<RapiTapir::Auth::Context user_id=#{user_id.inspect} scopes=#{@scopes.inspect} authenticated=#{authenticated?}>"
      end
    end

    # Thread-local context storage
    class ContextStore
      def self.current
        Thread.current[:rapitapir_auth_context]
      end

      def self.current=(context)
        Thread.current[:rapitapir_auth_context] = context
      end

      def self.with_context(context)
        old_context = current
        self.current = context
        yield
      ensure
        self.current = old_context
      end

      def self.clear
        Thread.current[:rapitapir_auth_context] = nil
      end
    end
  end
end
