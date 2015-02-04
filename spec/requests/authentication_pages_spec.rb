require 'spec_helper'

RSpec.describe "AuthenticationPages", :type => :request do

  subject { page }

  describe 'signin' do
    before { visit signin_path }

    describe 'with invalid information' do
      before { click_button 'Sign in' }

      it { should have_title('Sign in') }
      it { should have_selector('div.alert.alert-danger') }

      describe 'after visiting another page' do
        before { click_link 'Home' }
        it { should_not have_selector('div.alert.alert-danger') }
        it { should_not have_link('Profile') }
        it { should_not have_link('Settings') }
      end
    end

    describe 'with valid information' do
      let(:user) { FactoryGirl.create(:user) }

      before { sign_in user }

      it { should have_title(user.name) }
      it { should have_link('Users',       href: users_path) }
      it { should have_link('Profile',     href: user_path(user)) }
      it { should have_link('Settings',    href: edit_user_path(user)) }
      it { should have_link('Sign out',    href: signout_path) }
      it { should_not have_link('Sign in', href: signin_path) }

    end
  end

  describe 'authorization' do

    describe 'for non-signed-in users' do
      let(:user) { FactoryGirl.create(:user) }

      describe 'when attempting to visit a protected page' do
        before do
          visit edit_user_path(user)
          fill_in "Email",    with: user.email
          fill_in "Password", with: user.password
          click_button "Sign in"
        end

        describe 'after signin in' do
          it 'should render the desired protected page' do
            expect(page).to have_title('Edit user')
          end
        end
      end

      describe 'in the Users controller' do

        describe 'visiting the edit page' do
          before { visit edit_user_path(user) }
          it { should have_title('Sign in') }
        end

        describe 'submitting to the update action' do
          before { patch user_path(user) }
          specify { expect(response).to redirect_to(signin_path) }
        end

        describe 'visiting the user index' do
          before { visit users_path }
          it { should have_title('Sign in') }
        end
      end
    end

    describe 'as wrong user' do
      let(:user) { FactoryGirl.create(:user) }
      let(:wrong_user) { FactoryGirl.create(:user, email: 'wrong@example.com') }
      before { sign_in user, no_copybara: true }

      describe 'submitting a GET request to the Users#edit action' do
        before { get edit_user_path(wrong_user) }
        specify { expect(response.body).not_to match(full_title('Edit user')) }
        specify { expect(response).to redirect_to(root_path) }
      end
    end

    describe 'as non-admin user' do
      let(:user) { FactoryGirl.create(:user) }
      let(:non_admin) { FactoryGirl.create(:user) }
      before { sign_in non_admin, no_copybara: true }

      describe 'submitting a DELETE request to the Users#destroy action' do
        before { delete user_path(user) }
        specify { expect(response).to redirect_to(root_path) }
      end
    end

    describe "should redirect a logged in user to root url if user tries to hit new in users controller" do
      let(:user) {FactoryGirl.create(:user)}
      before do
        sign_in user, no_copybara: true
        get new_user_path
      end

      specify{expect(response).to redirect_to(root_path)}
    end

    describe "should redirect a logged in user to root url if user tries to hit create in users controller" do
      let(:params) do {user: {name: "Tester", email: "test@example.com", password: "password",
                              password_confirmation: "password"}}
      end
      let(:user) {FactoryGirl.create(:user)}

      before do
        sign_in user, no_copybara: true
        post users_path, params
      end

      specify{expect(response).to redirect_to(root_path)}
    end

    # describe "admin user should not delete himself " do
    #   let(:admin) { FactoryGirl.create(:admin) }
    #
    #   before do
    #     sign_in admin, no_copybara: true
    #     delete user_path(admin)
    #   end
    #   it { expect(page).to have_content('All users') }
    #   it { expect(page).to have_content("You can't delete yourself") }
    # end

    describe "as admin user" do
      let(:admin) { FactoryGirl.create(:admin) }
      before { sign_in admin, no_capybara: true }

      it "attempting to delete self" do
        expect{ delete user_path(admin) }.not_to change(User, :count)
      end
    end

  end
end