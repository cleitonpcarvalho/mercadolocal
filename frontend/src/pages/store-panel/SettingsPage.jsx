import { useMutation } from "@tanstack/react-query";
import { useState } from "react";
import toast from "react-hot-toast";

import { changePasswordRequest } from "../../services/authService";
import { getErrorMessage } from "../../utils/helpers";

function SettingsPage() {
  const [oldPassword, setOldPassword] = useState("");
  const [newPassword, setNewPassword] = useState("");

  const mutation = useMutation({
    mutationFn: changePasswordRequest,
    onSuccess: (payload) => {
      toast.success(payload?.message || "Senha atualizada com sucesso.");
      setOldPassword("");
      setNewPassword("");
    },
    onError: (error) => toast.error(getErrorMessage(error)),
  });

  const submit = (event) => {
    event.preventDefault();
    mutation.mutate({ old_password: oldPassword, new_password: newPassword });
  };

  return (
    <section className="space-y-4 rounded-2xl border border-red-100 bg-white p-5 shadow-sm">
      <h1 className="text-2xl font-extrabold">Configurações</h1>
      <form className="grid max-w-md gap-3" onSubmit={submit}>
        <input
          className="rounded-xl border border-red-100 px-4 py-3"
          minLength={8}
          onChange={(event) => setOldPassword(event.target.value)}
          placeholder="Senha atual"
          required
          type="password"
          value={oldPassword}
        />
        <input
          className="rounded-xl border border-red-100 px-4 py-3"
          minLength={8}
          onChange={(event) => setNewPassword(event.target.value)}
          placeholder="Nova senha"
          required
          type="password"
          value={newPassword}
        />

        <button
          className="rounded-xl bg-primary px-4 py-3 font-semibold text-white hover:bg-red-700"
          disabled={mutation.isPending}
          type="submit"
        >
          {mutation.isPending ? "Salvando..." : "Atualizar senha"}
        </button>
      </form>
    </section>
  );
}

export default SettingsPage;
