# frozen_string_literal: true

class Api::V1::UsersController < ApplicationController
  rapitapir do
    # User type definitions
    user_type = T.hash(
      id: T.integer,
      email: T.string,
      name: T.string,
      bio: T.string.optional,
      avatar_url: T.string.optional,
      created_at: T.string,
      updated_at: T.string,
      posts_count: T.integer
    )
    
    create_user_type = T.hash(
      email: T.string,
      name: T.string,
      bio: T.string.optional,
      password: T.string
    )
    
    update_user_type = T.hash(
      email: T.string.optional,
      name: T.string.optional,
      bio: T.string.optional
    )
    
    # List users with search and pagination
    GET('/api/v1/users')
      .in(query(:search, T.string.optional))
      .in(query(:page, T.integer.default(1)))
      .in(query(:per_page, T.integer.default(20)))
      .in(query(:sort, T.enum(['name', 'email', 'created_at']).default('created_at')))
      .in(query(:order, T.enum(['asc', 'desc']).default('desc')))
      .out(json_body(
        users: T.array(user_type),
        pagination: T.hash(
          page: T.integer,
          per_page: T.integer,
          total: T.integer,
          total_pages: T.integer,
          has_next: T.boolean,
          has_prev: T.boolean
        )
      ))
      .summary("List users")
      .description("Get a paginated list of users with optional search")
      .tag("Users")
    
    # Get user by ID
    GET('/api/v1/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(user: user_type))
      .summary("Get user")
      .description("Get a specific user by ID")
      .tag("Users")
    
    # Create new user
    POST('/api/v1/users')
      .in(json_body(create_user_type))
      .out(json_body(user: user_type), 201)
      .summary("Create user")
      .description("Create a new user account")
      .tag("Users")
    
    # Update user
    PUT('/api/v1/users/:id')
      .in(path(:id, T.integer))
      .in(json_body(update_user_type))
      .out(json_body(user: user_type))
      .summary("Update user")
      .description("Update an existing user")
      .tag("Users")
    
    # Delete user
    DELETE('/api/v1/users/:id')
      .in(path(:id, T.integer))
      .out(json_body(message: T.string))
      .summary("Delete user")
      .description("Delete a user account")
      .tag("Users")
    
    # Get user's posts
    GET('/api/v1/users/:id/posts')
      .in(path(:id, T.integer))
      .in(query(:published, T.boolean.optional))
      .in(query(:page, T.integer.default(1)))
      .out(json_body(
        posts: T.array(T.hash(
          id: T.integer,
          title: T.string,
          excerpt: T.string,
          published: T.boolean,
          created_at: T.string
        )),
        pagination: T.hash(
          page: T.integer,
          total: T.integer,
          total_pages: T.integer
        )
      ))
      .summary("Get user posts")
      .description("Get all posts by a specific user")
      .tag("Users")
  end
  
  def list_users
    users_scope = User.includes(:posts)
    
    # Apply search filter
    if inputs[:search].present?
      search_term = "%#{inputs[:search]}%"
      users_scope = users_scope.where(
        "name ILIKE ? OR email ILIKE ?", search_term, search_term
      )
    end
    
    # Apply sorting
    order_clause = "#{inputs[:sort]} #{inputs[:order]}"
    users_scope = users_scope.order(order_clause)
    
    # Pagination
    page = inputs[:page]
    per_page = [inputs[:per_page], 100].min # Cap at 100
    
    users = users_scope.page(page).per(per_page)
    
    {
      users: users.map { |user| serialize_user(user) },
      pagination: pagination_metadata(users_scope, page, per_page)
    }
  end
  
  def get_user
    user = User.includes(:posts).find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    { user: serialize_user(user) }
  end
  
  def create_user
    user = User.new(user_create_params)
    
    if user.save
      render json: { user: serialize_user(user) }, status: 201
    else
      render_error("Validation failed", 422, errors: user.errors.full_messages)
    end
  end
  
  def update_user
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    if user.update(user_update_params)
      { user: serialize_user(user) }
    else
      render_error("Validation failed", 422, errors: user.errors.full_messages)
    end
  end
  
  def delete_user
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    user.destroy
    { message: "User deleted successfully" }
  end
  
  def get_user_posts
    user = User.find_by(id: inputs[:id])
    return render_error("User not found", 404) unless user
    
    posts_scope = user.posts
    posts_scope = posts_scope.where(published: inputs[:published]) if inputs.key?(:published)
    
    page = inputs[:page]
    posts = posts_scope.page(page).per(10)
    
    {
      posts: posts.map { |post| serialize_post_summary(post) },
      pagination: pagination_metadata(posts_scope, page, 10)
    }
  end
  
  private
  
  def user_create_params
    inputs.slice(:email, :name, :bio, :password)
  end
  
  def user_update_params
    inputs.slice(:email, :name, :bio).compact
  end
  
  def serialize_user(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      bio: user.bio,
      avatar_url: user.avatar_url,
      created_at: user.created_at.iso8601,
      updated_at: user.updated_at.iso8601,
      posts_count: user.posts.count
    }
  end
  
  def serialize_post_summary(post)
    {
      id: post.id,
      title: post.title,
      excerpt: post.content.truncate(200),
      published: post.published,
      created_at: post.created_at.iso8601
    }
  end
end
