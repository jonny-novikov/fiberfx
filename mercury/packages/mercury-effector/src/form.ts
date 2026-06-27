import { createEvent, createStore } from "effector";
import { useUnit } from "effector-react";

export type FormErrors<V> = Partial<Record<keyof V, string>>;

export interface FormConfig<V> {
  initialValues: V;
  /** Pure validator: return a map of field → message for invalid fields. */
  validate?: (values: V) => FormErrors<V>;
}

export interface FieldBinding<T> {
  value: T;
  error: string | undefined;
  onChange: (value: T) => void;
  onBlur: () => void;
}

/**
 * createForm — an Effector-backed form model + React hooks.
 * Components stay presentational; the stores live outside React.
 */
export function createForm<V extends Record<string, unknown>>(config: FormConfig<V>) {
  const { initialValues, validate } = config;
  const keys = Object.keys(initialValues) as (keyof V)[];

  const changed = createEvent<{ name: keyof V; value: V[keyof V] }>();
  const blurred = createEvent<keyof V>();
  const submitted = createEvent();
  const reset = createEvent();

  const $values = createStore<V>(initialValues)
    .on(changed, (state, { name, value }) => ({ ...state, [name]: value }))
    .reset(reset);

  const $touched = createStore<Partial<Record<keyof V, boolean>>>({})
    .on(blurred, (state, name) => ({ ...state, [name]: true }))
    .on(submitted, () => Object.fromEntries(keys.map((k) => [k, true])) as Partial<Record<keyof V, boolean>>)
    .reset(reset);

  const $errors = $values.map((values): FormErrors<V> => (validate ? validate(values) : {}));
  const $isValid = $errors.map((errors) => Object.keys(errors).length === 0);

  function useField<K extends keyof V>(name: K): FieldBinding<V[K]> {
    const [values, errors, touched] = useUnit([$values, $errors, $touched]);
    return {
      value: values[name],
      error: touched[name] ? errors[name] : undefined,
      onChange: (value: V[K]) => changed({ name, value }),
      onBlur: () => blurred(name),
    };
  }

  function useForm() {
    const [values, errors, touched, isValid] = useUnit([$values, $errors, $touched, $isValid]);
    return {
      values,
      errors,
      touched,
      isValid,
      setField: <K extends keyof V>(name: K, value: V[K]) => changed({ name, value }),
      submit: () => submitted(),
      reset: () => reset(),
    };
  }

  return { $values, $errors, $touched, $isValid, changed, blurred, submitted, reset, useField, useForm };
}
