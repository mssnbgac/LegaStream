class Api::V1::AuthController < ApplicationController
  skip_before_action :authenticate_user!, only: [:login, :register, :confirm_email, :forgot_password, :reset_password]

  def register
    @user = User.new(user_params)
    
    if @user.save
      # Auto-confirm email - no email confirmation required
      @user.confirm_email!
      
      render json: {
        message: 'Registration successful! You can now log in.',
        user: user_response(@user)
      }, status: :created
    else
      render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def login
    @user = User.find_by(email: params[:email].downcase)
    
    if @user&.authenticate(params[:password])
      if @user.active? && !@user.locked?
        @user.update_last_login!
        token = generate_jwt_token(@user)
        
        render json: {
          token: token,
          user: user_response(@user),
          message: 'Login successful'
        }
      elsif @user.locked?
        render json: { error: 'Your account has been locked. Please contact support.' }, status: :unauthorized
      else
        render json: { error: 'Your account is inactive. Please contact support.' }, status: :unauthorized
      end
    else
      render json: { error: 'Invalid email or password' }, status: :unauthorized
    end
  end

  def confirm_email
    @user = User.find_by(confirmation_token: params[:token])
    
    if @user && @user.confirmation_token_valid?
      @user.confirm_email!
      render json: { 
        message: 'Email confirmed successfully! You can now log in.',
        confirmed: true 
      }
    else
      render json: { 
        error: 'Invalid or expired confirmation token',
        confirmed: false 
      }, status: :unprocessable_entity
    end
  end

  def resend_confirmation
    @user = User.find_by(email: params[:email].downcase)
    
    if @user && !@user.confirmed?
      @user.generate_confirmation_token
      @user.save!
      UserMailer.confirmation_email(@user).deliver_now
      
      render json: { message: 'Confirmation email sent successfully' }
    elsif @user&.confirmed?
      render json: { error: 'Email is already confirmed' }, status: :unprocessable_entity
    else
      render json: { error: 'User not found' }, status: :not_found
    end
  end

  def forgot_password
    @user = User.find_by(email: params[:email].downcase)
    
    if @user
      @user.generate_reset_password_token
      UserMailer.reset_password_email(@user).deliver_now
      render json: { message: 'Password reset instructions sent to your email' }
    else
      # Don't reveal if email exists or not for security
      render json: { message: 'If an account with that email exists, password reset instructions have been sent' }
    end
  end

  def reset_password
    @user = User.find_by(reset_password_token: params[:token])
    
    if @user && @user.reset_password_token_valid?
      if @user.reset_password!(params[:password])
        render json: { message: 'Password reset successfully' }
      else
        render json: { errors: @user.errors.full_messages }, status: :unprocessable_entity
      end
    else
      render json: { error: 'Invalid or expired reset token' }, status: :unprocessable_entity
    end
  end

  def logout
    # In a stateless JWT system, logout is handled client-side by removing the token
    render json: { message: 'Logged out successfully' }
  end

  def me
    render json: { user: user_response(current_user) }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name)
  end

  def user_response(user)
    {
      id: user.id,
      email: user.email,
      first_name: user.first_name,
      last_name: user.last_name,
      full_name: user.full_name,
      role: user.role,
      email_confirmed: user.email_confirmed,
      last_login_at: user.last_login_at,
      tenant: {
        id: user.tenant.id,
        name: user.tenant.name,
        subscription_tier: user.tenant.subscription_tier
      }
    }
  end

  def generate_jwt_token(user)
    payload = {
      user_id: user.id,
      tenant_id: user.tenant_id,
      exp: 24.hours.from_now.to_i
    }
    JWT.encode(payload, Rails.application.credentials.secret_key_base)
  end
end