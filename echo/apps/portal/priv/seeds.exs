# Minimal seed data so the F5.3 slices round-trip locally.
#
# The in-memory store empties on restart, and `mix run priv/seeds.exs` runs in a
# separate node that exits — so for a live server, seed inside one running node:
#
#     iex -S mix
#     iex> Code.eval_file("apps/portal/priv/seeds.exs")
#
# Ids are minted with Portal.ID.new/1 — real 14-char branded ids, never "USR1".
user = %Portal.Accounts.User{id: Portal.ID.new("USR"), email: "ada@example.com", name: "Ada Lovelace"}
course = %Portal.Catalog.Course{id: Portal.ID.new("CRS"), title: "Functional Programming in Elixir", slug: "elixir"}
lesson = %Portal.Catalog.Lesson{id: Portal.ID.new("LSN"), course_id: course.id, title: "Pattern Matching"}

Enum.each([user, course, lesson], &Portal.Store.put/1)

IO.puts("""
Seeded valid branded ids:
  user   = #{user.id}
  course = #{course.id}
  lesson = #{lesson.id}  (course_id=#{lesson.course_id})

Try (real ids):
  curl -s -X POST "localhost:4000/enroll?user=#{user.id}&course=#{course.id}"
  curl -s "localhost:4000/lessons/#{lesson.id}"
  curl -s "localhost:4000/courses/#{user.id}"
""")
