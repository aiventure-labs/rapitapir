# frozen_string_literal: true

class Api::V1::PostsController < ApplicationController
  rapitapir do
    # Type definitions
    post_type = T.hash(
      id: T.integer,
      title: T.string,
      content: T.string,
      excerpt: T.string,
      published: T.boolean,
      tags: T.array(T.string),
      user: T.hash(
        id: T.integer,
        name: T.string,
        email: T.string
      ),
      comments_count: T.integer,
      created_at: T.string,
      updated_at: T.string
    )
    
    # List posts with filtering
    GET('/api/v1/posts')
      .in(query(:published, T.boolean.optional))
      .in(query(:tag, T.string.optional))
      .in(query(:user_id, T.integer.optional))
      .in(query(:search, T.string.optional))
      .in(query(:page, T.integer.default(1)))
      .in(query(:per_page, T.integer.default(10)))
      .out(json_body(
        posts: T.array(post_type),
        pagination: T.hash(
          page: T.integer,
          per_page: T.integer,
          total: T.integer,
          total_pages: T.integer
        ),
        filters: T.hash(
          published: T.boolean.optional,
          tag: T.string.optional,
          user_id: T.integer.optional,
          search: T.string.optional
        )
      ))
      .summary("List posts")
      .description("Get posts with filtering and pagination")
      .tag("Posts")
    
    # Get specific post
    GET('/api/v1/posts/:id')
      .in(path(:id, T.integer))
      .in(query(:include_comments, T.boolean.default(false)))
      .out(json_body(
        post: post_type,
        comments: T.array(T.hash(
          id: T.integer,
          content: T.string,
          user: T.hash(id: T.integer, name: T.string),
          created_at: T.string
        )).optional
      ))
      .summary("Get post")
      .description("Get a specific post with optional comments")
      .tag("Posts")
    
    # Create post
    POST('/api/v1/posts')
      .in(json_body(
        title: T.string,
        content: T.string,
        published: T.boolean.default(false),
        tags: T.array(T.string).default([])
      ))
      .in(header(:authorization, T.string))
      .out(json_body(post: post_type), 201)
      .summary("Create post")
      .description("Create a new blog post")
      .tag("Posts")
    
    # Update post
    PUT('/api/v1/posts/:id')
      .in(path(:id, T.integer))
      .in(json_body(
        title: T.string.optional,
        content: T.string.optional,
        published: T.boolean.optional,
        tags: T.array(T.string).optional
      ))
      .in(header(:authorization, T.string))
      .out(json_body(post: post_type))
      .summary("Update post")
      .description("Update an existing post")
      .tag("Posts")
    
    # Delete post
    DELETE('/api/v1/posts/:id')
      .in(path(:id, T.integer))
      .in(header(:authorization, T.string))
      .out(json_body(message: T.string))
      .summary("Delete post")
      .description("Delete a blog post")
      .tag("Posts")
    
    # Publish/unpublish post
    PATCH('/api/v1/posts/:id/publish')
      .in(path(:id, T.integer))
      .in(json_body(published: T.boolean))
      .in(header(:authorization, T.string))
      .out(json_body(post: post_type))
      .summary("Toggle post publication")
      .description("Publish or unpublish a post")
      .tag("Posts")
  end
  
  before_action :authenticate_user!, only: [:create_post, :update_post, :delete_post, :toggle_publish]
  before_action :authorize_post_owner!, only: [:update_post, :delete_post, :toggle_publish]
  
  def list_posts
    posts_scope = Post.includes(:user, :comments)
    
    # Apply filters
    posts_scope = posts_scope.where(published: inputs[:published]) if inputs.key?(:published)
    posts_scope = posts_scope.where(user_id: inputs[:user_id]) if inputs[:user_id]
    posts_scope = posts_scope.joins(:tags).where(tags: { name: inputs[:tag] }) if inputs[:tag]
    
    # Search
    if inputs[:search].present?
      search_term = "%#{inputs[:search]}%"
      posts_scope = posts_scope.where(
        "title ILIKE ? OR content ILIKE ?", search_term, search_term
      )
    end
    
    # Pagination
    page = inputs[:page]
    per_page = inputs[:per_page]
    posts = posts_scope.order(created_at: :desc).page(page).per(per_page)
    
    {
      posts: posts.map { |post| serialize_post(post) },
      pagination: pagination_metadata(posts_scope, page, per_page),
      filters: inputs.slice(:published, :tag, :user_id, :search).compact
    }
  end
  
  def get_post
    post = Post.includes(:user, :comments, :tags).find_by(id: inputs[:id])
    return render_error("Post not found", 404) unless post
    
    response = { post: serialize_post(post) }
    
    if inputs[:include_comments]
      response[:comments] = post.comments.includes(:user).map do |comment|
        {
          id: comment.id,
          content: comment.content,
          user: {
            id: comment.user.id,
            name: comment.user.name
          },
          created_at: comment.created_at.iso8601
        }
      end
    end
    
    response
  end
  
  def create_post
    post = current_user.posts.build(post_params)
    
    if post.save
      add_tags_to_post(post, inputs[:tags]) if inputs[:tags]
      render json: { post: serialize_post(post.reload) }, status: 201
    else
      render_error("Validation failed", 422, errors: post.errors.full_messages)
    end
  end
  
  def update_post
    if @post.update(post_params.compact)
      add_tags_to_post(@post, inputs[:tags]) if inputs[:tags]
      { post: serialize_post(@post.reload) }
    else
      render_error("Validation failed", 422, errors: @post.errors.full_messages)
    end
  end
  
  def delete_post
    @post.destroy
    { message: "Post deleted successfully" }
  end
  
  def toggle_publish
    if @post.update(published: inputs[:published])
      { post: serialize_post(@post) }
    else
      render_error("Failed to update post", 422, errors: @post.errors.full_messages)
    end
  end
  
  private
  
  def authenticate_user!
    token = inputs[:authorization]&.sub(/^Bearer /, '')
    return render_error("Authorization required", 401) unless token
    
    # In a real app, you'd validate the JWT token here
    @current_user = User.find_by(auth_token: token)
    return render_error("Invalid token", 401) unless @current_user
  end
  
  def current_user
    @current_user
  end
  
  def authorize_post_owner!
    @post = Post.find_by(id: inputs[:id])
    return render_error("Post not found", 404) unless @post
    return render_error("Forbidden", 403) unless @post.user == current_user
  end
  
  def post_params
    inputs.slice(:title, :content, :published)
  end
  
  def add_tags_to_post(post, tag_names)
    post.tags.clear
    tag_names.each do |name|
      tag = Tag.find_or_create_by(name: name.strip.downcase)
      post.tags << tag unless post.tags.include?(tag)
    end
  end
  
  def serialize_post(post)
    {
      id: post.id,
      title: post.title,
      content: post.content,
      excerpt: post.content.truncate(200),
      published: post.published,
      tags: post.tags.pluck(:name),
      user: {
        id: post.user.id,
        name: post.user.name,
        email: post.user.email
      },
      comments_count: post.comments.count,
      created_at: post.created_at.iso8601,
      updated_at: post.updated_at.iso8601
    }
  end
end
