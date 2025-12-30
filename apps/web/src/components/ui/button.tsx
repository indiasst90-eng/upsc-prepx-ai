import * as React from "react"
import { Slot } from "@radix-ui/react-slot"
import { cva, type VariantProps } from "class-variance-authority"

import { cn } from "@/lib/utils"

const buttonVariants = cva(
  "inline-flex items-center justify-center whitespace-nowrap text-sm font-semibold transition-all duration-200 focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-offset-2 disabled:pointer-events-none disabled:opacity-50",
  {
    variants: {
      variant: {
        // Primary - Neon gradient with neumorphic shadow
        default: [
          "rounded-xl px-6 py-3 text-white",
          "bg-gradient-to-br from-[var(--neon-blue)] to-[var(--neon-purple)]",
          "shadow-[0_4px_15px_rgba(0,243,255,0.3),inset_0_1px_2px_rgba(255,255,255,0.1)]",
          "hover:shadow-[0_6px_20px_rgba(0,243,255,0.5),inset_0_1px_2px_rgba(255,255,255,0.1)]",
          "hover:-translate-y-0.5",
          "active:translate-y-0"
        ],
        // Secondary - Neumorphic style
        secondary: [
          "rounded-xl px-6 py-3 text-foreground",
          "bg-[rgba(30,30,50,0.5)]",
          "border border-white/10",
          "shadow-[3px_3px_6px_var(--neuro-shadow-dark),-2px_-2px_4px_var(--neuro-shadow-light)]",
          "hover:bg-[rgba(40,40,60,0.6)]",
          "hover:shadow-[4px_4px_8px_var(--neuro-shadow-dark),-3px_-3px_6px_var(--neuro-shadow-light)]"
        ],
        // Ghost - Minimal with hover
        ghost: [
          "rounded-xl px-6 py-3 text-foreground",
          "bg-transparent border border-white/5",
          "hover:bg-white/5 hover:border-white/10"
        ],
        // Danger - Red neon gradient
        destructive: [
          "rounded-xl px-6 py-3 text-white",
          "bg-gradient-to-br from-[var(--neon-pink)] to-[#ff0044]",
          "shadow-[0_4px_15px_rgba(255,0,107,0.3)]",
          "hover:shadow-[0_6px_20px_rgba(255,0,107,0.5)]",
          "hover:-translate-y-0.5"
        ],
        // Glass - Glassmorphic style
        glass: [
          "rounded-xl px-6 py-3 text-white",
          "bg-white/5 backdrop-blur-md border border-white/10",
          "hover:bg-white/10 hover:shadow-[0_4px_20px_rgba(0,243,255,0.2)]"
        ],
        // Neon - Extra glow effect
        neon: [
          "rounded-xl px-6 py-3 text-white",
          "bg-gradient-to-r from-[var(--neon-blue)] to-[var(--neon-purple)]",
          "shadow-[0_0_10px_rgba(0,243,255,0.3)]",
          "hover:shadow-[0_0_20px_rgba(188,19,254,0.5)]",
          "animate-pulse-glow"
        ],
        // Link - Minimal text style
        link: "text-primary underline-offset-4 hover:underline px-0",
        // Outline - Border style
        outline: [
          "rounded-xl px-6 py-3",
          "border border-input bg-background",
          "hover:bg-accent hover:text-accent-foreground"
        ],
      },
      size: {
        default: "h-auto",
        sm: "h-auto px-4 py-2 text-sm rounded-lg",
        lg: "h-auto px-8 py-4 text-base rounded-xl",
        icon: "h-10 w-10 p-2 rounded-xl",
      },
    },
    defaultVariants: {
      variant: "default",
      size: "default",
    },
  }
)

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean
}

const Button = React.forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant, size, asChild = false, ...props }, ref) => {
    const Comp = asChild ? Slot : "button"
    return (
      <Comp
        className={cn(buttonVariants({ variant, size, className }))}
        ref={ref}
        {...props}
      />
    )
  }
)
Button.displayName = "Button"

export { Button, buttonVariants }
