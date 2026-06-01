# F6.05 · Templates, components & HEEx

> The view module. F6.01 ended with a controller returning a response; HEEx is how that response becomes HTML. A
> template is a pure function of its assigns, repeated markup becomes a typed function component, and a form is a
> changeset turned into editable fields. This guide ships the **build prompts** that produce an index template that
> renders the assigns the controller set, a reusable `course_card` component declared with `attr` and `slot`, a
> changeset-backed `<.form>` with inline errors, and the create action that closes the loop back to the context. Run
> them in order and verify against the definition of done.

Module guide · part of [F6 · Phoenix Framework](phoenix.md) · prev: [F6.04 · contexts](f6-04-contexts.md)

## What you'll build

The view half of the catalog, server-rendered:

- an **index template** (`index.html.heex`) that renders `@courses` with `:for`, a `~p` link per course,
  interpolation for the title, and an `:if` empty-state — no `Repo`, no context call;
- a **`course_card` function component** declared with `attr :course, :map, required: true` and an optional `:class`,
  replacing the per-row markup;
- a **slot-based wrapper** (`panel`) using `slot :inner_block` and `render_slot/1` to frame caller content;
- a **changeset-backed form** — `to_form/1` over `Catalog.change_course/1`, rendered with `<.form>` and `<.input>`;
- the **create action** that sends params to `Catalog.create_course/1`, redirects on `{:ok, _}`, and re-renders with
  `to_form(changeset)` on `{:error, _}` so the F6.03 errors appear inline;
- the **discipline** that keeps data access in the controller and out of the template.

## Concepts

- **A template is a pure function of its assigns.** The controller sets `@courses`; the template renders it. Same
  assigns, same HTML. No queries, no context calls, no process state in the template.
- **Three constructs.** Curly `{ }` interpolation renders a value; `:for={c <- @courses}` loops; `:if={cond}` guards.
  `:for` and `:if` are attributes on a real element, not wrapping block tags.
- **Escaping is default.** Interpolated values are HTML-escaped, so a title containing a tag is shown as text. The XSS
  hole is closed without ceremony.
- **`~p` links are verified.** A typo in a route path is a compile error (F6.02), not a broken anchor.
- **Components are functions with a typed interface.** `def name(assigns)` returning `~H`, declared with `attr` and
  `slot`. The compiler warns on a missing required attr or an unknown one — a partial fails at runtime, a component at
  compile time.
- **Slots wrap content.** `slot :inner_block` plus `render_slot(@inner_block)` lets a component frame caller-supplied
  markup, the basis of layout and panel components.
- **Forms are changesets rendered.** `to_form/1` wraps a changeset; `<.form>` renders the element and a CSRF token;
  `<.input field={@form[:title]}>` renders one field with its value and errors. One changeset drives both the write and
  the error display.
- **The loop closes in the controller.** Submit → context `create` → `{:ok, _}` redirects, `{:error, cs}` re-wraps with
  `to_form` and re-renders. The template never changes between the two outcomes; only the changeset's errors do.

## Specs

**The index template (`@courses` assign):**

| Construct | Use |
| --- | --- |
| `:for={course <- @courses}` | one `<li>` per course |
| `<.link navigate={~p"/courses/#{course.id}"}>` | verified per-course link |
| `{course.title}` | escaped interpolation |
| `:if={course.published}` | conditional badge |
| `:if={@courses == []}` | empty state |

**The `course_card` component:**

| Element | Value |
| --- | --- |
| `attr :course, :map, required: true` | the struct to render |
| `attr :class, :string, default: ""` | optional extra classes |
| body | `~H` returning an `<article>` with `{@course.title}` and an `:if` badge |
| call | `<.course_card :for={course <- @courses} course={course} />` |

**The form:**

| Element | Value |
| --- | --- |
| build | `to_form(Catalog.change_course(%Course{}))` |
| render | `<.form for={@form} action={~p"/courses"}>` |
| field | `<.input field={@form[:title]} label="Title" />` |
| submit | params → `Catalog.create_course/1` → `{:ok, _}` redirect / `{:error, cs}` re-render |

**Touched files:** `lib/portal_web/controllers/course_html/index.html.heex`, `course_html/new.html.heex`,
`lib/portal_web/controllers/course_controller.ex`, `lib/portal_web/components/catalog_components.ex` (or
`core_components.ex`), and `Portal.Catalog.change_course/1` (a changeset wrapper).

## Build it

1. **The index template** — render assigns, nothing more.

   ```heex
   <h1>Courses</h1>
   <ul class="courses">
     <li :for={course <- @courses} class="course">
       <.link navigate={~p"/courses/#{course.id}"}>{course.title}</.link>
       <span :if={course.published} class="badge">published</span>
     </li>
   </ul>
   <p :if={@courses == []}>No courses yet.</p>
   ```

2. **The controller assign** — fetch through the facade.

   ```elixir
   def index(conn, _params), do: render(conn, :index, courses: Portal.list_courses())
   ```

3. **The `course_card` component** — typed, reusable.

   ```elixir
   attr :course, :map, required: true
   attr :class, :string, default: ""

   def course_card(assigns) do
     ~H"""
     <article class={["card", @class]}>
       <h3>{@course.title}</h3>
       <p :if={@course.published} class="badge">Published</p>
     </article>
     """
   end
   ```

4. **A slot wrapper** — frame caller content.

   ```elixir
   slot :inner_block, required: true
   def panel(assigns) do
     ~H"""
     <section class="panel">{render_slot(@inner_block)}</section>
     """
   end
   ```

5. **The form and the create action** — one changeset, two outcomes.

   ```elixir
   def new(conn, _params),
     do: render(conn, :new, form: to_form(Catalog.change_course(%Course{})))

   def create(conn, %{"course" => params}) do
     case Catalog.create_course(params) do
       {:ok, course} ->
         conn |> put_flash(:info, "Course created") |> redirect(to: ~p"/courses/#{course.id}")
       {:error, %Ecto.Changeset{} = changeset} ->
         render(conn, :new, form: to_form(changeset))
     end
   end
   ```

   ```heex
   <.form for={@form} action={~p"/courses"}>
     <.input field={@form[:title]} label="Title" />
     <.input field={@form[:published]} type="checkbox" label="Published" />
     <.button>Save</.button>
   </.form>
   ```

6. **Verify.** Templates contain no `Repo` or context query; the card warns at compile time if `course` is omitted;
   submitting an invalid title re-renders the form with the error beside the field; the valid path redirects.

## Build prompts

> Paste into an agent in order. Each prompt carries its spec and acceptance criteria. The app stays runnable after
> each one.

```text
PROMPT 1 — The index template over assigns
Create course_html/index.html.heex that renders @courses: a heading, a <ul> with :for={course <- @courses}, a
<.link navigate={~p"/courses/#{course.id}"}> showing {course.title}, an :if badge for published, and an :if empty
state for @courses == []. Set the assign in CourseController.index via render(conn, :index, courses:
Portal.list_courses()). The template must contain no Repo call and no Catalog call.
Acceptance: visiting /courses lists courses from the facade; the title is HTML-escaped; the link uses a verified ~p
path; an empty catalog shows the empty state; a grep finds no Repo or Catalog reference in the .heex file.
```

```text
PROMPT 2 — The course_card function component
In a components module (use Phoenix.Component), declare attr :course, :map, required: true and attr :class, :string,
default: "" and define course_card(assigns) returning ~H that renders an <article> with {@course.title} and an :if
published badge, using class={["card", @class]}. The component must not fetch the course; it renders whatever %Course{}
it is given.
Acceptance: the component compiles; omitting course produces a compile-time warning naming the missing attr; passing an
unknown attribute warns; rendering with a %Course{} produces the article markup; the component contains no data access.
```

```text
PROMPT 3 — Compose the card and add a slot wrapper
Replace the per-row <li> markup in index.html.heex with <.course_card :for={course <- @courses} course={course} />.
Separately, add a panel/1 component with slot :inner_block, required: true that renders <section class="panel">
{render_slot(@inner_block)}</section>, and show it wrapping arbitrary content: <.panel><p>...</p></.panel>.
Acceptance: the index renders one card per course via the component; the list markup now lives in one place; the panel
renders whatever content is placed between its tags; changing the card markup changes every page that uses it.
```

```text
PROMPT 4 — A changeset-backed form
Add Portal.Catalog.change_course/1 returning a changeset for a %Course{}. In CourseController.new, build the form with
to_form(Catalog.change_course(%Course{})) and render new.html.heex with <.form for={@form} action={~p"/courses"}>, an
<.input field={@form[:title]} label="Title" />, an <.input field={@form[:published]} type="checkbox" />, and a
<.button>Save</.button>. Do not write a raw <form> tag or a manual CSRF field.
Acceptance: GET /courses/new renders the form with a hidden CSRF token; inputs are bound to the changeset fields; the
form posts to the create route via a verified ~p path; no raw <form> element or hand-written token appears.
```

```text
PROMPT 5 — Create with inline errors
Implement CourseController.create/2 that takes %{"course" => params}, calls Catalog.create_course(params), redirects
with a flash on {:ok, course}, and on {:error, %Ecto.Changeset{} = cs} re-renders new with form: to_form(cs). Confirm
<.input> shows the F6.03 validation messages beside the offending fields on the re-render, with the user's input
preserved.
Acceptance: submitting a valid course redirects with a flash and persists via the context; submitting an invalid title
re-renders the same form with the error shown inline and the entered values kept; the controller branches on the tagged
tuple, never on raw Ecto internals beyond matching %Ecto.Changeset{}.
```

```text
PROMPT 6 — Verify the view layer
Confirm end to end: no .heex template contains a Repo or context query; the course_card warns at compile time when its
required attr is missing; the index renders cards from @courses set by the controller; the new/create cycle round-trips
— valid input redirects, invalid input re-renders with inline errors and preserved values. The F6.04 contexts and F6.03
changesets are unchanged.
Acceptance: a grep shows data access only in controllers and contexts, never in templates; the component interface is
compile-checked; the form cycle works both ways; existing context and changeset tests pass unchanged.
```

## Definition of done

- [ ] Templates render assigns only — no `Repo`, no context query in any `.heex`.
- [ ] `:for`, `:if`, and `{ }` interpolation are used as attributes/holes; values are escaped; links use `~p`.
- [ ] `course_card` declares `attr`/`slot`; a missing required attr warns at compile time.
- [ ] `render_slot/1` frames caller content in a slot-based component.
- [ ] The form is `to_form(changeset)` rendered with `<.form>`/`<.input>`; no raw `<form>` or manual CSRF.
- [ ] Create redirects on success and re-renders inline F6.03 errors on failure, with input preserved.

## Next

F6.06 · LiveView — make these same templates live: mount, handle events, and re-render only what changed over a
socket, without a full page reload.
