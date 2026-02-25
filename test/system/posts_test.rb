require "application_system_test_case"

class PostsTest < ApplicationSystemTestCase
  setup do
    @user = users(:one)
    @post = posts(:one)
  end

  def sign_in_as(user)
    visit new_session_url
    fill_in "email_address", with: user.email_address
    fill_in "password", with: "password"
    click_on "Sign in"
  end

  test "visiting the index" do
    visit root_url
    assert_selector "article.post"
  end

  test "should create post" do
    sign_in_as @user

    fill_in "Content", with: "A brand new post"
    click_on "Post"

    assert_text "Post was successfully created"
  end

  test "should update Post" do
    sign_in_as @user
    visit post_url(@post)
    click_on "Edit"

    fill_in "Content", with: "Updated content"
    click_on "Update Post"

    assert_text "Post was successfully updated"
  end

  test "should destroy Post" do
    sign_in_as @user
    visit post_url(@post)

    accept_confirm "Are you sure?" do
      click_on "Delete"
    end

    assert_text "Post was successfully destroyed"
  end
end
