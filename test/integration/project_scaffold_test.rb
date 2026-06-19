# frozen_string_literal: true

# ATDD Green-Phase Tests — Story 1.1: Project Initialization & Platform Scaffold
#
# All tests activated after implementation is complete.
#
# Acceptance Criteria Covered:
#   AC-1: Rails 8 boots with PostgreSQL + Tailwind+daisyUI (no Node); .gitignore correct
#   AC-2: CI pipeline runs all 6 gates and fails on high/critical findings
#   AC-3: Kamal 2 + Thruster deploy config — no secrets in source

require "test_helper"

class ProjectScaffoldTest < ActiveSupport::TestCase
  # ---------------------------------------------------------------------------
  # AC-1: .gitignore covers required credential patterns (P0, R-002)
  # ---------------------------------------------------------------------------

  test "[P0] .gitignore excludes master.key" do
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{^config/master\.key$}m, gitignore,
                 ".gitignore must contain 'config/master.key'"
  end

  test "[P0] .gitignore excludes credentials key files" do
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{config/credentials/\*\.key}m, gitignore,
                 ".gitignore must contain 'config/credentials/*.key'"
  end

  test "[P0] .gitignore excludes .env files" do
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{^\.env(\.\*)?$}m, gitignore,
                 ".gitignore must contain '.env' and '.env.*'"
  end

  test "[P0] .gitignore excludes .pem files" do
    gitignore = File.read(Rails.root.join(".gitignore"))
    assert_match %r{\*\.pem}m, gitignore,
                 ".gitignore must contain '*.pem'"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Rails application configuration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] application is configured for Bangkok timezone" do
    assert_equal "Bangkok", Rails.application.config.time_zone,
                 "config.time_zone must be 'Bangkok'"
  end

  test "[P1] application default locale is English" do
    assert_equal :en, Rails.application.config.i18n.default_locale,
                 "config.i18n.default_locale must be :en"
  end

  test "[P1] application available locales include English and Thai" do
    assert_includes Rails.application.config.i18n.available_locales, :en
    assert_includes Rails.application.config.i18n.available_locales, :th
  end

  test "[P1] database adapter is PostgreSQL" do
    assert_equal "postgresql", ActiveRecord::Base.connection_db_config.adapter,
                 "database.yml must configure the postgresql adapter"
  end

  # ---------------------------------------------------------------------------
  # AC-1: daisyUI bundled files committed (no Node/CDN) (P1, R-010)
  # ---------------------------------------------------------------------------

  test "[P1] daisyui.mjs is committed to app/assets/tailwind" do
    assert File.exist?(Rails.root.join("app/assets/tailwind/daisyui.mjs")),
           "daisyui.mjs must be committed to app/assets/tailwind/ (no CDN)"
  end

  test "[P1] daisyui-theme.mjs is committed to app/assets/tailwind" do
    assert File.exist?(Rails.root.join("app/assets/tailwind/daisyui-theme.mjs")),
           "daisyui-theme.mjs must be committed to app/assets/tailwind/ (no CDN)"
  end

  test "[P1] application.css imports tailwindcss and daisyUI plugins" do
    css = File.read(Rails.root.join("app/assets/tailwind/application.css"))
    assert_match '@import "tailwindcss"', css,
                 "application.css must contain '@import \"tailwindcss\"'"
    assert_match '@plugin "./daisyui.mjs"', css,
                 "application.css must contain '@plugin \"./daisyui.mjs\"'"
    assert_match '@plugin "./daisyui-theme.mjs"', css,
                 "application.css must contain '@plugin \"./daisyui-theme.mjs\"'"
    assert_match '@source not "./daisyui{,*}.mjs"', css,
                 "application.css must exclude daisyUI source from Tailwind scanning"
  end

  test "[P1] no node_modules directory exists at project root" do
    refute Dir.exist?(Rails.root.join("node_modules")),
           "node_modules must not exist — architecture requires zero Node/npm"
  end

  test "[P1] package.json does not exist at project root" do
    refute File.exist?(Rails.root.join("package.json")),
           "package.json must not exist — architecture requires zero Node/npm"
  end

  # ---------------------------------------------------------------------------
  # AC-2: CI pipeline declares all required gates (P0, R-002)
  # ---------------------------------------------------------------------------

  test "[P0] CI workflow file exists at .github/workflows/ci.yml" do
    assert File.exist?(Rails.root.join(".github/workflows/ci.yml")),
           ".github/workflows/ci.yml must exist"
  end

  test "[P0] CI workflow includes RuboCop step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "rubocop", ci_yml,
                 "CI workflow must include a RuboCop step"
  end

  test "[P0] CI workflow includes Brakeman step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "brakeman", ci_yml,
                 "CI workflow must include a Brakeman step"
  end

  test "[P0] CI workflow includes bundler-audit step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "bundler-audit", ci_yml,
                 "CI workflow must include a bundler-audit step"
  end

  test "[P0] CI workflow includes gitleaks step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "gitleaks", ci_yml,
                 "CI workflow must include a gitleaks step"
  end

  test "[P0] CI workflow includes Minitest step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    rails_test_pattern = /rails test|bundle exec rails test/i
    assert_match(rails_test_pattern, ci_yml,
                 "CI workflow must run the Minitest suite")
  end

  test "[P0] CI workflow includes i18n-tasks health step" do
    ci_yml = File.read(Rails.root.join(".github/workflows/ci.yml"))
    assert_match "i18n-tasks", ci_yml,
                 "CI workflow must run i18n-tasks health check"
  end

  # ---------------------------------------------------------------------------
  # AC-3: Kamal deploy config — no secrets in source (P0, R-002, R-014)
  # ---------------------------------------------------------------------------

  test "[P0] config/deploy.yml exists" do
    assert File.exist?(Rails.root.join("config/deploy.yml")),
           "config/deploy.yml must exist for Kamal 2 configuration"
  end

  test "[P0] config/deploy.yml contains no hardcoded secret values" do
    deploy_yml = File.read(Rails.root.join("config/deploy.yml"))

    # Secrets must be referenced via ENV or Kamal secret references, never hardcoded
    refute_match(/password:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded password value")
    refute_match(/secret:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded secret value")
    refute_match(/private_key:\s+["']?[A-Za-z0-9!@#$%^&*]{8,}/, deploy_yml,
                 "deploy.yml must not contain a hardcoded private key")
  end

  test "[P0] Dockerfile exists for Kamal 2 deployment" do
    assert File.exist?(Rails.root.join("Dockerfile")),
           "Dockerfile must exist (Rails 8 default + Thruster entrypoint)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Gemfile includes required gems (P1)
  # ---------------------------------------------------------------------------

  test "[P1] Gemfile includes required runtime gems" do
    gemfile = File.read(Rails.root.join("Gemfile"))
    %w[pg omniauth_openid_connect pundit view_component prawn rqrcode
       solid_queue solid_cache solid_cable tailwindcss-rails lograge].each do |gem_name|
      assert_match gem_name, gemfile,
                   "Gemfile must include the '#{gem_name}' gem"
    end
  end

  test "[P1] Gemfile includes required development/test gems" do
    gemfile = File.read(Rails.root.join("Gemfile"))
    %w[rubocop-rails-omakase brakeman bundler-audit i18n-tasks].each do |gem_name|
      assert_match gem_name, gemfile,
                   "Gemfile must include the '#{gem_name}' gem in development/test group"
    end
  end

  test "[P1] Gemfile does not include forbidden gems" do
    gemfile = File.read(Rails.root.join("Gemfile"))
    refute_match(/^\s*gem ['"]rspec/, gemfile,
                 "Gemfile must NOT include RSpec — Minitest is the confirmed framework")
    refute_match(/^\s*gem ['"]redis/, gemfile,
                 "Gemfile must NOT include Redis — infrastructure is DB-backed (Solid Queue/Cache/Cable)")
  end

  # ---------------------------------------------------------------------------
  # AC-1: btree_gist extension migration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] btree_gist extension migration exists" do
    migration_files = Dir.glob(Rails.root.join("db/migrate/*enable_btree*.rb"))
    assert migration_files.any?,
           "A migration enabling btree_gist extension must exist in db/migrate/"
  end

  test "[P1] btree_gist extension is enabled in the database schema" do
    # Check schema.rb for btree_gist enable_extension declaration
    schema = File.read(Rails.root.join("db/schema.rb"))
    assert_match 'enable_extension "btree_gist"', schema,
                 "db/schema.rb must include enable_extension \"btree_gist\" after running the migration"
  end

  # ---------------------------------------------------------------------------
  # AC-1: i18n locale files (P1, R-007)
  # ---------------------------------------------------------------------------

  test "[P1] en.yml locale file exists" do
    assert File.exist?(Rails.root.join("config/locales/en.yml")),
           "config/locales/en.yml must exist"
  end

  test "[P1] th.yml locale file exists as key-mirror stub" do
    assert File.exist?(Rails.root.join("config/locales/th.yml")),
           "config/locales/th.yml must exist as a key-mirror stub for Thai"
  end

  # ---------------------------------------------------------------------------
  # AC-1: Solid Queue configuration (P1)
  # ---------------------------------------------------------------------------

  test "[P1] config/queue.yml exists for Solid Queue" do
    assert File.exist?(Rails.root.join("config/queue.yml")),
           "config/queue.yml must exist for Solid Queue configuration"
  end

  test "[P1] config/recurring.yml stub exists" do
    assert File.exist?(Rails.root.join("config/recurring.yml")),
           "config/recurring.yml stub must exist (recurring jobs added in Story 1.6)"
  end

  # ---------------------------------------------------------------------------
  # AC-1: ApplicationMailer scaffold (P2)
  # ---------------------------------------------------------------------------

  test "[P2] ApplicationMailer exists" do
    assert defined?(ApplicationMailer), "ApplicationMailer class must be defined"
  end

  test "[P2] ApplicationMailer inherits ActionMailer::Base" do
    assert ApplicationMailer < ActionMailer::Base,
           "ApplicationMailer must inherit from ActionMailer::Base"
  end

  # ---------------------------------------------------------------------------
  # AC-1: ApplicationController minimal scaffold (P2)
  # ---------------------------------------------------------------------------

  test "[P2] ApplicationController exists and inherits ActionController::Base" do
    assert defined?(ApplicationController), "ApplicationController class must be defined"
    assert ApplicationController < ActionController::Base,
           "ApplicationController must inherit from ActionController::Base"
  end

  test "[P2] ApplicationController includes Pundit::Authorization (added in Story 1.4)" do
    # Story 1.1 placeholder test was inverted — Story 1.4 adds Pundit::Authorization.
    ancestors = ApplicationController.ancestors
    assert_includes ancestors, Pundit::Authorization,
                    "ApplicationController must include Pundit::Authorization (Story 1.4)"
  end
end
