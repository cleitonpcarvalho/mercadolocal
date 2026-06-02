import { create } from "zustand";
import { createJSONStorage, persist } from "zustand/middleware";

export const useCartStore = create(
  persist(
    (set, get) => ({
      items: [],
      deliveryLocation: null,
      deliveryAddress: "",
      paymentMethod: "pix",

      addItem: (product) => {
        set((state) => {
          const existing = state.items.find((item) => item.id === product.id);
          if (existing) {
            return {
              items: state.items.map((item) =>
                item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item
              ),
            };
          }

          return {
            items: [
              ...state.items,
              {
                id: product.id,
                name: product.name,
                price: Number(product.price || 0),
                storeId: product.store?.id,
                storeName: product.store?.name,
                image: product.images?.[0]?.image || product.first_image || "",
                condition: product.condition,
                quantity: 1,
              },
            ],
          };
        });
      },

      removeItem: (id) => {
        set((state) => ({
          items: state.items.filter((item) => item.id !== id),
        }));
      },

      updateQuantity: (id, quantity) => {
        if (quantity <= 0) {
          get().removeItem(id);
          return;
        }

        set((state) => ({
          items: state.items.map((item) =>
            item.id === id ? { ...item, quantity } : item
          ),
        }));
      },

      clearCart: () => {
        set({ items: [] });
      },

      setDeliveryLocation: (location) => {
        set({ deliveryLocation: location });
      },

      setDeliveryAddress: (deliveryAddress) => {
        set({ deliveryAddress });
      },

      setPaymentMethod: (paymentMethod) => {
        set({ paymentMethod });
      },
    }),
    {
      name: "cart-storage",
      storage: createJSONStorage(() => localStorage),
    }
  )
);
