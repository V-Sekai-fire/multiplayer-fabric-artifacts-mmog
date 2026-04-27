import Config

config :instructor,
  adapter: Instructor.Adapters.OpenAI,
  openai: [
    api_key: System.get_env("OPENROUTER_API_KEY", "local"),
    api_url: "https://openrouter.ai/api"
  ]
